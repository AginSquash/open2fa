//
//  Core2FA_ViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 05.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import SwiftUI
import GAuthDecrypt
import CloudKit
import RealmSwift
import SwiftOTP
import Combine
import UIKit

@MainActor
class Core2FA_ViewModel: ObservableObject {
    
    @Published private(set) var codes: [AccountCurrentCode] = []
    @Published private(set) var timeRemaning: Int = 0
    @Published var isActive: Bool = false
    @Published private(set) var progress: CGFloat = 1.0
    @Published var needsSecurityUpgrade: Bool = false
    @Published var deferSecurityUpgrade: Bool = false

    private var accountsData = [AccountData]()
    private var sessionKey: Data?
    private var kdfParams: KDFParams

    private var storage: StorageService
    var notificationToken: NotificationToken?
    
    private var cryptoModule: CryptoService?
    
    private var willResignActiveDate = Date()
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldPopView = false {
        didSet {
            if shouldPopView {
                free()
            }
            viewDismissalModePublisher.send(shouldPopView)
        }
    }
    
    private var timer: Timer?
    
    @objc func updateTime() {
        timeRemaning -= 1
        
        if timeRemaning <= 0 {
            timeRemaning = 30
            self.codes = self.getOTPList()
        }
        progress = CGFloat( Double(timeRemaning) / 30 )
    }
    
    func getOTPList() -> [AccountCurrentCode] {
        var accountsCurrentCode: [AccountCurrentCode] = []
        for account in accountsData {
            guard let totp = TOTP(secret: account.secret),
                  let currentCode = totp.generate(time: Date()) else { continue }
            let newACC = AccountCurrentCode(account, currentCode: currentCode)
            accountsCurrentCode.append(newACC)
        }
        return accountsCurrentCode
    }
    
    func addAccount(name: String, issuer: String, secret: String) -> String? {
        guard let cryptoModule else { return "Locked" }
        guard let baase32Decoded = secret.base32DecodedData,
              let totp = TOTP(secret: baase32Decoded),
              let _ = totp.generate(time: Date()) else { return "Incorrect secret" }
        
        let newAccount = AccountData(name: name, issuer: issuer, secret: baase32Decoded)
        let accountObject = AccountObject(newAccount, cm: cryptoModule)
        guard accountObject.account_data != nil else { return "Cannot encrypt" }
        try? storage.saveOrUpdateObject(object: accountObject)
        
        self.accountsData.append(newAccount)
        self.codes = getOTPList()
        
        return nil
    }
    
    func updateAccounts() {
        guard let cryptoModule else { return }
        let data = storage.fetch(by: AccountObject.self).filter { !$0.isDeleted }
        self.accountsData = data.compactMap { AccountData($0, cm: cryptoModule) }.sorted()
        self.codes = getOTPList()
    }
    
    func editAccount(serviceID: String, newName: String, newIssuer: String) -> String? {
        guard let cryptoModule else { return "Locked" }
        guard let index = self.accountsData.firstIndex(where: { $0.id == serviceID }) else { return nil }
        accountsData[index].name = newName
        accountsData[index].issuer = newIssuer
        accountsData[index].modified_date = Date()
        
        let accountObject = AccountObject(accountsData[index], cm: cryptoModule)
        guard accountObject.account_data != nil else { return "Cannot encrypt" }
        try? storage.saveOrUpdateObject(object: accountObject)
        
        self.codes = getOTPList()
        return nil
    }
    
    func deleteService(uuid: String) {
        try? storage.deleteObjectWithId(type: AccountObject.self, id: uuid)
        accountsData.removeAll { $0.id == uuid }
        withAnimation {
            self.codes.removeAll(where: { $0.id == uuid } )
        }
    }

    func accountForExport(id: String) -> AccountData? {
        guard let cryptoModule,
              let object = storage.account(id: id),
              !object.isDeleted else { return nil }
        return AccountData(object, cm: cryptoModule)
    }
    
    func importFromGAuth(gauthString: String) -> Int {
     guard let decryprtedGAuth = GAuthDecryptFrom(string: gauthString) else {
            return 0
        }
        
        var count = 0
        for decrypted in decryprtedGAuth {
            if decrypted.type == .hotp { continue }
            
            _ = self.addAccount(name: decrypted.name, issuer: decrypted.issuer, secret: decrypted.secret)
            count += 1
        }
        
        return count
    }

    func importAccounts(accounts: [AccountData]) throws {
        guard let cryptoModule else { throw VaultUnlockError.cryptoFailure }
        let accountObjects = accounts.map { AccountObject($0, cm: cryptoModule) }
        guard accountObjects.allSatisfy({ $0.account_data != nil }) else { throw VaultUnlockError.cryptoFailure }
        try storage.saveOrUpdateAllObjects(objects: accountObjects)
        updateAccounts()
    }

    func verifyPassword(_ password: String) async -> Bool {
        guard let sessionKey else { return false }
        guard let derived = try? await Self.deriveKeychainKey(password: password) else { return false }
        return CryptoService.constantTimeEqual(derived, sessionKey)
    }

    func enrollBiometricKey() throws {
        guard let sessionKey else { throw VaultUnlockError.keyNotSaved }
        try KeychainService.shared.setKey(sessionKey)
    }

    func upgradeEncryption(password: String) async throws {
        guard kdfParams.needsUpgrade else {
            needsSecurityUpgrade = false
            return
        }
        guard await verifyPassword(password) else { throw VaultUnlockError.wrongPassword }
        try await reencrypt(to: password)
    }

    func changePassword(current: String, newPassword: String) async throws {
        if let reason = PasswordPolicy.rejectionReason(newPassword) {
            throw VaultUnlockError.weakPassword(reason)
        }
        guard await verifyPassword(current) else { throw VaultUnlockError.wrongPassword }
        try await reencrypt(to: newPassword)
    }
        
    private init(sessionKey: Data, params: KDFParams, storage: StorageService = .shared, attachLifecycle: Bool) {
        self.sessionKey = sessionKey
        self.kdfParams = params
        self.cryptoModule = CryptoService(key: sessionKey)
        self.storage = storage
        self.needsSecurityUpgrade = params.needsUpgrade

        guard attachLifecycle else { return }
        self.initTimer()
        self.setObservers()
        self.notificationToken = storage.realm?.observe { [weak self] _, _ in
            self?.updateAccounts()
        }
    }

    private func free() {
        self.timer?.invalidate()
        self.timer = nil
        self.notificationToken?.invalidate()
        self.notificationToken = nil
        NotificationCenter.default.removeObserver(self)
        wipeSession()
        _debugPrint("core free")
    }
    
    deinit {
        self.notificationToken?.invalidate()
        NotificationCenter.default.removeObserver(self)
        _debugPrint("DEINT")
    }
    
    func syncTimer() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "ss"
        let time = Int(df.string(from: date))!
        
        self.timeRemaning = (time > 30) ? 60 - time : 30 - time
        self.progress = CGFloat( Double(timeRemaning) / 30 )
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.syncEngine?.pull()
        self.updateAccounts()
    }
    
    func setObservers() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(willResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(didBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    @objc func willResignActiveNotification() {
        self.isActive = false
        self.willResignActiveDate = Date()
        self.timer?.invalidate()
        self.timer = nil
        wipePlaintext()
    }
    
    @objc func didBecomeActiveNotification() {
        Task { @MainActor in
            await checkShouldPopView()
            guard self.isActive, self.sessionKey != nil else { return }
            self.restoreCryptoModule()
            self.syncTimer()
            self.initTimer()
        }
    }
    
    private func initTimer() {
        guard self.timer?.isValid != true else { return }
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    private func checkShouldPopView() async {
        let lockTimeout = UserDefaults.standard.double(forKey: AppSettings.SettingsKeys.lockTimeout.rawValue)
        let deadline = willResignActiveDate.addingTimeInterval(lockTimeout)
        if Date() <= deadline {
            self.isActive = true
            return
        }
        guard UserDefaultsService.get(key: .storageLocalKeychainEnable) else {
            self.shouldPopView = true
            return
        }
        do {
            let context = try await BiometricAuthService.authenticatedContext()
            guard let key = KeychainService.shared.getKey(context: context),
                  let iv = KeychainService.shared.getIV_KVC(),
                  let kvc = KeychainService.shared.getKVC() else {
                self.shouldPopView = true
                return
            }
            let params = KeychainService.shared.loadParams()
            let crypto = CryptoService(key: key)
            let opens = crypto.openKVC(iv: iv, kvc: kvc, cipherVersion: params.cipherVersion)
            crypto.wipe()
            guard opens else {
                KeychainService.shared.removeKey()
                self.shouldPopView = true
                return
            }
            if var old = sessionKey {
                old.resetBytes(in: 0..<old.count)
            }
            sessionKey = key
            cryptoModule?.wipe()
            cryptoModule = nil
            self.isActive = true
        } catch {
            self.shouldPopView = true
        }
    }

    private func wipePlaintext() {
        accountsData.removeAll()
        codes.removeAll()
        cryptoModule?.wipe()
        cryptoModule = nil
    }

    private func wipeSession() {
        wipePlaintext()
        if var key = sessionKey {
            key.resetBytes(in: 0..<key.count)
            sessionKey = key
        }
        sessionKey = nil
        isActive = false
    }

    private func restoreCryptoModule() {
        guard cryptoModule == nil, let sessionKey else { return }
        cryptoModule = CryptoService(key: sessionKey)
    }

    private func reencrypt(to password: String) async throws {
        guard let cryptoModule else { throw VaultUnlockError.cryptoFailure }
        let live = storage.fetch(by: AccountObject.self).filter { !$0.isDeleted && $0.account_data?.isEmpty == false }
        let decoded = live.compactMap { AccountData($0, cm: cryptoModule) }
        guard decoded.count == live.count else { throw VaultUnlockError.incompleteVault }

        let params = KDFParams.current
        let saltString = try CryptoService.generateSalt()
        guard let salt = CryptoService.saltData(stored: saltString, isBase64: true) else {
            throw VaultUnlockError.cryptoFailure
        }
        let newKey = try await CryptoService.deriveKey(password: password, salt: salt, iterations: params.iterations)
        let newCrypto = CryptoService(key: newKey)
        let sealedKVC = try newCrypto.sealKVC()
        let wrapped = try cryptoModule.encrypt(plaintext: newKey)
        var updates: [AccountBlobUpdate] = []
        for account in decoded {
            let encoded = try JSONEncoder().encode(account)
            let sealed = try newCrypto.encrypt(plaintext: encoded)
            updates.append(AccountBlobUpdate(
                id: account.id,
                iv: sealed.iv,
                accountData: sealed.ciphertext,
                cipherVersion: params.cipherVersion
            ))
        }

        let wrap = VaultMigrationWrap()
        wrap.id = VaultMigrationWrap.singletonID
        wrap.salt = saltString
        wrap.ivKVC = sealedKVC.iv
        wrap.kvc = sealedKVC.kvc
        wrap.paramsJSON = try JSONEncoder().encode(params)
        wrap.wrappedKey = wrapped.ciphertext
        wrap.wrapIV = wrapped.iv
        wrap.wrapCipherVersion = params.cipherVersion

        try storage.commitReencryption(updates: updates, wrap: wrap)
        KeychainService.shared.setSalt(salt: saltString)
        KeychainService.shared.setIV_KVC(iv: [UInt8](sealedKVC.iv))
        KeychainService.shared.setKVC(kvc: sealedKVC.kvc)
        KeychainService.shared.saveParams(params)
        try storage.clearMigrationWrap()

        KeychainService.shared.removeKey()
        if UserDefaultsService.get(key: .storageLocalKeychainEnable) {
            try? KeychainService.shared.setKey(newKey)
        }

        cryptoModule.wipe()
        self.cryptoModule = newCrypto
        if var old = sessionKey {
            old.resetBytes(in: 0..<old.count)
        }
        self.sessionKey = newKey
        self.kdfParams = params
        self.needsSecurityUpgrade = false
        updateAccounts()

        if UserDefaultsService.get(key: .cloudSync) {
            try? await CloudKitService.uploadPublicEncryptData()
            (UIApplication.shared.delegate as? AppDelegate)?.syncEngine?.pushAll()
        }
    }
}

extension Core2FA_ViewModel {
    static func unlock(password: String, saveKey: Bool, enforcePolicy: Bool) async throws -> Core2FA_ViewModel {
        if enforcePolicy, let reason = PasswordPolicy.rejectionReason(password) {
            throw VaultUnlockError.weakPassword(reason)
        }
        if KeychainService.shared.getKVC() == nil {
            if UserDefaultsService.get(key: .alreadyInited) || StorageService.shared.hasLiveCiphertext() {
                throw VaultUnlockError.needsRecovery
            }
            return try await bootstrap(password: password, saveKey: saveKey)
        }

        let key = try await deriveKeychainKey(password: password)
        let params = KeychainService.shared.loadParams()
        guard let iv = KeychainService.shared.getIV_KVC(),
              let kvc = KeychainService.shared.getKVC() else {
            throw VaultUnlockError.needsRecovery
        }
        let crypto = CryptoService(key: key)
        guard crypto.openKVC(iv: iv, kvc: kvc, cipherVersion: params.cipherVersion) else {
            crypto.wipe()
            throw VaultUnlockError.wrongPassword
        }
        let resolved = try resolvePendingWrap(using: crypto, currentKey: key, currentParams: params)
        crypto.wipe()
        if saveKey && !resolved.params.needsUpgrade && (!UserDefaultsService.get(key: .biometricKeyStored) || resolved.key != key) {
            try? KeychainService.shared.setKey(resolved.key)
        }
        let core = Core2FA_ViewModel(sessionKey: resolved.key, params: resolved.params, attachLifecycle: true)
        if resolved.params.needsUpgrade {
            do {
                try await core.reencrypt(to: password)
            } catch {
                core.needsSecurityUpgrade = true
                _debugPrint(error)
            }
        }
        core.isActive = true
        return core
    }

    static func unlockWithBiometrics() async throws -> Core2FA_ViewModel {
        let context = try await BiometricAuthService.authenticatedContext()
        guard let key = KeychainService.shared.getKey(context: context) else {
            throw VaultUnlockError.keyNotSaved
        }
        let params = KeychainService.shared.loadParams()
        guard let iv = KeychainService.shared.getIV_KVC(),
              let kvc = KeychainService.shared.getKVC() else {
            KeychainService.shared.removeKey()
            throw VaultUnlockError.needsRecovery
        }
        let crypto = CryptoService(key: key)
        guard crypto.openKVC(iv: iv, kvc: kvc, cipherVersion: params.cipherVersion) else {
            crypto.wipe()
            KeychainService.shared.removeKey()
            throw VaultUnlockError.wrongPassword
        }
        let resolved = try resolvePendingWrap(using: crypto, currentKey: key, currentParams: params)
        crypto.wipe()
        if resolved.key != key {
            try? KeychainService.shared.setKey(resolved.key, context: context)
        }
        let core = Core2FA_ViewModel(sessionKey: resolved.key, params: resolved.params, attachLifecycle: true)
        core.needsSecurityUpgrade = resolved.params.needsUpgrade
        core.isActive = true
        return core
    }

    private static func bootstrap(password: String, saveKey: Bool) async throws -> Core2FA_ViewModel {
        let params = KDFParams.current
        let saltString = try CryptoService.generateSalt()
        guard let salt = CryptoService.saltData(stored: saltString, isBase64: true) else {
            throw VaultUnlockError.cryptoFailure
        }
        let key = try await CryptoService.deriveKey(password: password, salt: salt, iterations: params.iterations)
        let crypto = CryptoService(key: key)
        let sealed = try crypto.sealKVC()
        crypto.wipe()
        KeychainService.shared.setSalt(salt: saltString)
        KeychainService.shared.setIV_KVC(iv: [UInt8](sealed.iv))
        KeychainService.shared.setKVC(kvc: sealed.kvc)
        KeychainService.shared.saveParams(params)
        if saveKey {
            try? KeychainService.shared.setKey(key)
        }
        let core = Core2FA_ViewModel(sessionKey: key, params: params, attachLifecycle: true)
        core.isActive = true
        return core
    }

    private static func deriveKeychainKey(password: String) async throws -> Data {
        let params = KeychainService.shared.loadParams()
        guard KDFParams.isAllowed(params),
              let saltString = KeychainService.shared.getSalt(),
              let salt = CryptoService.saltData(stored: saltString, isBase64: params.saltIsBase64) else {
            throw VaultUnlockError.needsRecovery
        }
        do {
            return try await CryptoService.deriveKey(password: password, salt: salt, iterations: params.iterations)
        } catch {
            throw VaultUnlockError.cryptoFailure
        }
    }

    private static func resolvePendingWrap(using crypto: CryptoService, currentKey: Data, currentParams: KDFParams) throws -> (key: Data, params: KDFParams) {
        guard let wrap = StorageService.shared.migrationWrap() else {
            return (currentKey, currentParams)
        }
        if KeychainService.shared.getSalt() == wrap.salt {
            try StorageService.shared.clearMigrationWrap()
            return (currentKey, currentParams)
        }
        guard let newKey = crypto.decrypt(iv: wrap.wrapIV, payload: wrap.wrappedKey, cipherVersion: wrap.wrapCipherVersion),
              let adopted = try? JSONDecoder().decode(KDFParams.self, from: wrap.paramsJSON),
              KDFParams.isAllowed(adopted) else {
            throw VaultUnlockError.incompleteVault
        }
        let checker = CryptoService(key: newKey)
        let opens = checker.openKVC(iv: [UInt8](wrap.ivKVC), kvc: wrap.kvc, cipherVersion: adopted.cipherVersion)
        checker.wipe()
        guard opens else { throw VaultUnlockError.incompleteVault }

        KeychainService.shared.setSalt(salt: wrap.salt)
        KeychainService.shared.setIV_KVC(iv: [UInt8](wrap.ivKVC))
        KeychainService.shared.setKVC(kvc: wrap.kvc)
        KeychainService.shared.saveParams(adopted)
        try StorageService.shared.clearMigrationWrap()
        return (newKey, adopted)
    }
}

extension Core2FA_ViewModel {
    static var TestModel: Core2FA_ViewModel {
        let core = Core2FA_ViewModel(
            sessionKey: Data(repeating: 0x11, count: 32),
            params: .current,
            storage: StorageService(inMemory: true),
            attachLifecycle: true
        )
        core.isActive = true
        _ = core.addAccount(name: "Test 1", issuer: "TestIssuer 1", secret: "q4qghrcn2c42bgbz")
        _ = core.addAccount(name: "Test 2", issuer: "TestIssuer 2", secret: "q4qghrcn2c42bgbz")
        _ = core.addAccount(name: "Test 3", issuer: "TestIssuer 3", secret: "q4qghrcn2c42bgbz")
        return core
    }
}
