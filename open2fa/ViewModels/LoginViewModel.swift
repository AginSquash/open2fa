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

class LoginViewModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var isEnablelocalKeychain: Bool = true
    @Published var isEnableCloudSync: Bool = true
    @Published var cloudSyncAvailable: Bool = true
    @Published var enteredPassword: String = ""
    @Published var enteredPasswordSecond = ""
    @Published var errorDiscription: errorType? = nil
    @Published var showCloudLoadedAlert: Bool = false
    
    @Published var core: Core2FA_ViewModel?
    
    @Published var publicEncryptData: PublicEncryptData? = nil
    @Published var isLoadedFromCloud: Bool = false
    @Published var isFirstRun: Bool
    
    var appSettings = AppSettings()
    
    var isDisableLoginButton: Bool {
        return (enteredPassword != enteredPasswordSecond && isFirstRun) || ( enteredPassword.isEmpty )
    }
    
    var availableBiometricAuth: String
    var availableBiometricAuthImg: String
    
    init() {
        self.isFirstRun = !UserDefaultsService.get(key: .alreadyInited)
        
        let biometricType = LAContext().biometricType
        availableBiometricAuth = biometricType.rawValue
        availableBiometricAuthImg = biometricType.rawValue.lowercased()
        
        if isFirstRun {
            KeychainService.shared.reset() //Just in case reinstall for "fresh" init
            Task { await loadCloudSyncAvailable() }
            Task { await getSavedFromCloud() }
        } else {
            self.isEnablelocalKeychain = UserDefaultsService.get(key: .storageLocalKeychainEnable)
        }
    }
    
    func loginButtonAction() {
        if isFirstRun || publicEncryptData != nil {
            UserDefaultsService.set(isEnablelocalKeychain, forKey: .storageLocalKeychainEnable)
            UserDefaultsService.set(isEnableCloudSync, forKey: .cloudSync)
            UserDefaultsService.set(true, forKey: .alreadyInited)
        }
        
        self.core = nil
        guard let core = Core2FA_ViewModel(password: self.enteredPassword, saveKey: isEnablelocalKeychain) else { self.errorDiscription = .init(error: .passwordIncorrect); return }
        self.core = core
        self.core?.isActive = true
        self.enteredPassword = ""
        
        if isFirstRun && isEnableCloudSync {
            Task { try? await CloudKitService.uploadPublicEncryptData() }
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.syncEngine = SyncEngine(objects: [
                SyncObject(type: AccountObject.self)
            ])
        }
        pushMainView()
    }
    
    func onAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: tryBiometricAuth)
    }
    
    func deleteCloudData() {
        Task {
            try? await CloudKitService.deleteAllAccounts()
            try? await CloudKitService.deleteAllPublicEncryptData()
        }
    }
    
    func restoreCloudData() {
        guard let publicED = publicEncryptData else { return }
        KeychainService.shared.setSalt(salt: publicED.salt)
        KeychainService.shared.setIV_KVC(iv: publicED.iv_kvc)
        KeychainService.shared.setKVC(kvc: publicED.kvc)
        
        isEnableCloudSync = true
        isFirstRun = false
        isLoadedFromCloud = true
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.syncEngine = SyncEngine(objects: [
            SyncObject(type: AccountObject.self)
        ])
        delegate.syncEngine?.pull()
    }
    
    func disableCloud() {
        isEnableCloudSync = false
        cloudSyncAvailable = false
    }
    
    
    func tryBiometricAuth() {
        self.core = nil
        if !isFirstRun {
            BiometricAuthService.tryBiometricAuth { result in
                switch result {
                case .success(let isAuth):
                    guard isAuth else { return }
                    guard let key = KeychainService.shared.getKey() else { self.errorDiscription = .init(error: .keyNotSaved); return }
                    guard let core = Core2FA_ViewModel(key: key) else { self.errorDiscription = .init(error: .passwordIncorrect); return }
                    self.core = core
                    self.pushMainView()
                default:
                    _debugPrint("Biometric error")
                }
            }
        }
    }
    
    func importHandler(_ result: Bool) {
        if result {
            isFirstRun = false
            isEnablelocalKeychain = UserDefaultsService.get(key: .storageLocalKeychainEnable)
            tryBiometricAuth()
        }
    }
    
    private func pushMainView() {
        withAnimation {
             self.isUnlocked = true
        }
    }
    
    private func getSavedFromCloud() async {
        let records = try? await CloudKitService.fetchPublicEncryptData()
        guard let records = records else { return }
        await MainActor.run {
            publicEncryptData = records.first
            showCloudLoadedAlert = publicEncryptData != nil
        }
    }
    
    private func loadCloudSyncAvailable() async {
        let result = try? await CloudKitService.checkAccountStatus()
        guard let result = result else { return }
        await MainActor.run {
            cloudSyncAvailable = (result == .available)
            isEnableCloudSync = cloudSyncAvailable
        }
    }
}

extension LoginViewModel {
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
}
