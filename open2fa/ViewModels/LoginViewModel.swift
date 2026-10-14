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

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var isEnablelocalKeychain: Bool = true
    @Published var isEnableCloudSync: Bool = true
    @Published var cloudSyncAvailable: Bool = true
    @Published var enteredPassword: String = ""
    @Published var enteredPasswordSecond = ""
    @Published var errorDiscription: errorType? = nil
    @Published var showCloudLoadedAlert: Bool = false
    @Published var isUnlocking: Bool = false
    @Published var remoteCryptoUpdated: Bool = false
    
    @Published var core: Core2FA_ViewModel?
    
    @Published var publicEncryptData: PublicEncryptData? = nil
    @Published var isLoadedFromCloud: Bool = false
    @Published var isFirstRun: Bool
    
    var appSettings = AppSettings()
    
    var isDisableLoginButton: Bool {
        if enteredPassword.isEmpty || isUnlocking { return true }
        if isFirstRun {
            if enteredPassword != enteredPasswordSecond { return true }
            if PasswordPolicy.rejectionReason(enteredPassword) != nil { return true }
        }
        return false
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
        guard !isUnlocking else { return }
        isUnlocking = true
        let password = enteredPassword
        let saveKey = isEnablelocalKeychain
        let firstRun = isFirstRun
        let enableCloud = isEnableCloudSync
        Task {
            defer { isUnlocking = false }
            do {
                let core = try await Core2FA_ViewModel.unlock(password: password, saveKey: saveKey, enforcePolicy: firstRun)
                if firstRun || publicEncryptData != nil {
                    UserDefaultsService.set(saveKey, forKey: .storageLocalKeychainEnable)
                    UserDefaultsService.set(enableCloud, forKey: .cloudSync)
                    UserDefaultsService.set(true, forKey: .alreadyInited)
                }
                self.core = core
                self.enteredPassword = ""
                self.enteredPasswordSecond = ""
                if firstRun && enableCloud {
                    try? await CloudKitService.uploadPublicEncryptData()
                    let delegate = UIApplication.shared.delegate as? AppDelegate
                    delegate?.syncEngine = SyncEngine(objects: [
                        SyncObject(type: AccountObject.self)
                    ])
                }
                pushMainView()
            } catch let error as VaultUnlockError {
                self.core = nil
                self.errorDiscription = .from(error)
            } catch {
                self.core = nil
                self.errorDiscription = .init(error: .cannotCreateCore2FA)
            }
        }
    }
    
    func onAppear() {
        Task {
            let updated = await refreshRemoteCryptoParamsIfNeeded()
            if updated {
                remoteCryptoUpdated = true
            } else {
                tryBiometricAuth()
            }
        }
    }
    
    func deleteCloudData() {
        Task {
            try? await CloudKitService.deleteAllAccounts()
            try? await CloudKitService.deleteAllPublicEncryptData()
        }
    }
    
    func restoreCloudData() {
        guard let publicED = publicEncryptData else { return }
        KeychainService.shared.apply(publicED)
        
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
        guard !isFirstRun, !isUnlocking else { return }
        
        Task { @MainActor in
            do {
                let core = try await Core2FA_ViewModel.unlockWithBiometrics()
                self.core = core
                self.pushMainView()
            } catch VaultUnlockError.keyNotSaved {
                self.errorDiscription = .init(error: .keyNotSaved)
            } catch {
                _debugPrint("Biometric error: \(error)")
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
        let newest = records.max { lhs, rhs in rhs.kdfParams.isNewer(than: lhs.kdfParams) }
        await MainActor.run {
            publicEncryptData = newest
            showCloudLoadedAlert = publicEncryptData != nil
        }
    }
    
    private func refreshRemoteCryptoParamsIfNeeded() async -> Bool {
        guard !isFirstRun, UserDefaultsService.get(key: .cloudSync) else { return false }
        guard let records = try? await CloudKitService.fetchPublicEncryptData() else { return false }
        guard let remote = records.max(by: { lhs, rhs in
            rhs.kdfParams.isNewer(than: lhs.kdfParams)
        }) else { return false }
        let local = KeychainService.shared.loadParams()
        guard remote.kdfParams.isNewer(than: local), KDFParams.isAllowed(remote.kdfParams) else { return false }
        KeychainService.shared.apply(remote)
        KeychainService.shared.removeKey()
        (UIApplication.shared.delegate as? AppDelegate)?.syncEngine?.pull()
        return true
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
            case needsRecovery
            case weakPassword
        }
        
        let id = UUID()
        let error: errorTypeEnum
        var message: String? = nil

        init(error: errorTypeEnum, message: String? = nil) {
            self.error = error
            self.message = message
        }

        static func from(_ error: VaultUnlockError) -> errorType {
            switch error {
            case .wrongPassword:
                return errorType(error: .passwordIncorrect)
            case .needsRecovery, .incompleteVault:
                return errorType(error: .needsRecovery)
            case .weakPassword(let message):
                return errorType(error: .weakPassword, message: message)
            case .keyNotSaved:
                return errorType(error: .keyNotSaved)
            case .cryptoFailure:
                return errorType(error: .cannotCreateCore2FA)
            }
        }
    }
}
