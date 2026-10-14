//
//  PreferencesViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 03.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import SwiftUI
import IceCream

@MainActor
class PreferencesViewModel: ObservableObject {
    @Published var isEnableLocalKeychain: Bool = false
    @Published var showKeychainText: Bool = false
    @Published var isEnableCloudSync: Bool = false
    @Published var showConfirmCloudSyncAlert: Bool = false
    
    @Published var isCloudAlreadyUsed: Bool = false
    @Published var cloudSyncAvailable: Bool = true
    @Published var showDeleteCloudAlert: Bool = false
    
    var isRollbackCloud: Bool = false
    private var isRollbackKeychain = false
    
    
    init() {
        isEnableLocalKeychain = UserDefaultsService.get(key: .storageLocalKeychainEnable)
        isEnableCloudSync = UserDefaultsService.get(key: .cloudSync)
        
        Task { await loadCloudSyncAvailable() }
        Task { await getSavedFromCloud() }
    }
    
    func onChangeLocalKeychain(_ value: Bool, core: Core2FA_ViewModel) {
        guard !isRollbackKeychain else {
            isRollbackKeychain = false
            return
        }
        if value {
            do {
                try core.enrollBiometricKey()
                UserDefaultsService.set(true, forKey: .storageLocalKeychainEnable)
                showKeychainText = false
            } catch {
                isRollbackKeychain = true
                isEnableLocalKeychain = false
                showKeychainText = true
            }
        } else {
            KeychainService.shared.removeKey()
            UserDefaultsService.set(false, forKey: .storageLocalKeychainEnable)
            showKeychainText = false
        }
    }
    
    func toggleBackCloud() {
        self.isRollbackCloud = true
        self.isEnableCloudSync.toggle()
    }
    
    func onChangeCloudSync(_ value: Bool) {
        guard !self.isRollbackCloud else { self.isRollbackCloud = false; return }
        if value {
            if isCloudAlreadyUsed {
                showDeleteCloudAlert = true
            } else {
                enableCloud()
            }
        } else {
            showConfirmCloudSyncAlert = true
        }
    }
    
    func disableCloud() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.syncEngine = nil
        UserDefaultsService.set(false, forKey: .cloudSync)
        Task { try? await CloudKitService.deleteAllAccounts() }
        Task { try? await CloudKitService.deleteAllPublicEncryptData() }
        isCloudAlreadyUsed = false
    }
    
    func enableCloud() {
        UserDefaultsService.set(true, forKey: .cloudSync)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.syncEngine = SyncEngine(objects: [
            SyncObject(type: AccountObject.self)
        ])
        delegate.syncEngine?.pushAll()
        Task { try? await CloudKitService.uploadPublicEncryptData() }
        isCloudAlreadyUsed = true
    }
    
    func deleteFromCloudAndEnableSync() {
        Task {
            try? await CloudKitService.deleteAllAccounts()
            try? await CloudKitService.deleteAllPublicEncryptData()
            
            await MainActor.run {
                self.enableCloud()
            }
        }
    }
    
    private func getSavedFromCloud() async {
        let records = try? await CloudKitService.fetchPublicEncryptData()
        guard let records = records else { return }
        await MainActor.run {
            isCloudAlreadyUsed = !records.isEmpty
        }
    }
    
    private func loadCloudSyncAvailable() async {
        let result = try? await CloudKitService.checkAccountStatus()
        guard let result = result else { return }
        await MainActor.run {
            cloudSyncAvailable = (result == .available)
        }
    }
}
