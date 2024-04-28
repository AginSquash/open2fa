//
//  LoginViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import LocalAuthentication
import SwiftUI
import IceCream

struct errorType: Identifiable {
    enum errorTypeEnum {
        case passwordIncorrect
        case thisFileNotExist
        case passwordDontMatch
        case keyNotSaved
        case cannotCreateCore2FA
    }
    
    let id = UUID()
    let error: errorTypeEnum
}

enum UserDefaultsTags: String {
    case storageLocalKeychainEnable = "isEnableLocalKeyChain"
    case cloudSync = "isEnableCloudSync"
}

class LoginViewModel: ObservableObject {
    
    @Published var isUnlocked: Bool = false
    @Published var isEnablelocalKeychain: Bool = true
    @Published var isEnableCloudSync: Bool = true
    @Published var cloudSyncAvailable: Bool = true
    @Published var enteredPassword: String = ""
    @Published var enteredPasswordSecond = ""
    @Published var errorDiscription: errorType? = nil
    
    @Published var core: Core2FA_ViewModel?
    
    @Published var publicEncryptData: PublicEncryptData? = nil
    
    let isFirstRun: Bool
    
    var isDisableLoginButton: Bool {
        return (enteredPassword != enteredPasswordSecond && isFirstRun) || ( enteredPassword.isEmpty )
    }
    
    init() {
        self.isFirstRun = ( KeychainService.shared.getKVC() == nil )
        if !isFirstRun {
            self.isEnablelocalKeychain = UserDefaultsService.get(key: .storageLocalKeychainEnable)
        }
        
        Task {
            await loadCloudSyncAvailable()
        }
        
        if true { // isFirstRun
            Task {
                await getSavedFromCloud()
            }
        }
    }
    
    func loginButtonAction() {
        
        if self.isFirstRun {
            UserDefaultsService.set(isEnablelocalKeychain, forKey: .storageLocalKeychainEnable)
            UserDefaultsService.set(isEnableCloudSync, forKey: .cloudSync)
            
            if isEnablelocalKeychain {
                guard let core = Core2FA_ViewModel(password: self.enteredPassword, saveKey: true) else { self.errorDiscription = .init(error: .cannotCreateCore2FA); return }
                self.core = core
                if isEnableCloudSync {
                    core.savePublicEncryptData()
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.syncEngine = SyncEngine(objects: [
                        SyncObject(type: AccountObject.self)
                    ])
                }
                pushView()
                return
            }
        }
        
        guard let core = Core2FA_ViewModel(password: self.enteredPassword, saveKey: isEnablelocalKeychain) else { self.errorDiscription = .init(error: .passwordIncorrect); return }
        self.core = core
        
        if isFirstRun && isEnableCloudSync {
            core.savePublicEncryptData()
        }
        pushView()
    }
    
    func onAppear() {
        if isEnablelocalKeychain {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: biometricAuth)
        }
    }
    
    func tryBiometricAuth() {
        if isEnablelocalKeychain {
            biometricAuth()
        }
    }
    
    private func biometricAuth() {
        let context = LAContext()
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            return
        }
        
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                DispatchQueue.main.async {
                    guard let key = KeychainService.shared.getKey() else { self.errorDiscription = .init(error: .keyNotSaved); return }
                    guard let core = Core2FA_ViewModel(key: key) else { self.errorDiscription = .init(error: .passwordIncorrect); return }
                    self.core = core
                    self.pushView()
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func pushView() {
        withAnimation {
             self.isUnlocked = true
        }
    }
    
    func getSavedFromCloud() async {
        let records = try? await CloudKitService.fetchPublicEncryptData()
        guard let records = records else { return }
        await MainActor.run {
            publicEncryptData = records.first
        }
    }
    
    func loadCloudSyncAvailable() async {
        let result = try? await CloudKitService.checkAccountStatus()
        guard let result = result else { return }
        await MainActor.run {
            cloudSyncAvailable = (result == .available)
            isEnableCloudSync = cloudSyncAvailable
        }
    }
}
