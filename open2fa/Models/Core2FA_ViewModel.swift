//
//  Core2FA_ViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 05.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import GAuthDecrypt
import CloudKit
import RealmSwift
import SwiftOTP

class Core2FA_ViewModel: ObservableObject {
    
    @Published var codes: [AccountCurrentCode] = []
    @Published var timeRemaning: Int = 0
    @Published var isActive: Bool = true
    @Published var progress: CGFloat = 1.0

    @Published var accountsData = [AccountData]()

    /// Realm
    private var storage: StorageService
    var notificationToken: NotificationToken?
    
    /// Crypto
    private var cryptoModule: CryptoModule?
    
    private var timer: Timer?
    
    @objc func updateTime() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "ss"
        let time = Int(df.string(from: date))!
        
        if (time == 0 || time == 30) {
            self.codes = self.getOTPList()
        }
        
        if time > 30 {
            timeRemaning = 60 - time
        } else {
            timeRemaning = 30 - time
        }
        
        progress = CGFloat( Double(timeRemaning) / 30 )
    }
    
    func getOTPList() -> [AccountCurrentCode] {
        var accountsCurrentCode: [AccountCurrentCode] = []
        for account in accountsData {
            guard let totp = TOTP(secret: account.secret) else { continue }
            guard let currentCode = totp.generate(time: Date()) else { continue }
            let newACC = AccountCurrentCode(account, currentCode: currentCode)
            accountsCurrentCode.append(newACC)
        }
        return accountsCurrentCode
    }
    
    func deleteService(uuid: String) {
        try? storage.deleteObjectWithId(type: AccountObject.self, id: uuid)
        withAnimation {
            self.codes.removeAll(where: { $0.id == uuid } )
        }
    }
    
    func DEBUG() {
        /*
        _ = core.AddAccount(account_name: "Test1", issuer: "Google", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test2", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test3", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test4", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test5", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test6_extralargenamewillbehere", issuer: "CompanyWExtraLargeName", secret: "q4qghrcn2c42bgbz")
         */
    }
    
    func addAccount(name: String, issuer: String, secret: String) -> String? {
        guard let cm = cryptoModule else { return nil }
        guard let baase32Decoded = secret.base32DecodedData else { return "Incorrect secret" } // TODO: result?
        
        guard let totp = TOTP(secret: baase32Decoded) else { return "Incorrect secret" }
        guard let otp = totp.generate(time: Date()) else { return "Incorrect secret" }
        
        let newAccount = AccountData(name: name, issuer: issuer, secret: baase32Decoded)
        let accountObject = AccountObject(newAccount, cm: cm)
        try? storage.saveOrUpdateObject(object: accountObject)
        
        self.accountsData.append(newAccount)
        self.codes = getOTPList()
        
        return nil
    }
    
    func editAccount(serviceID: String, newName: String, newIssuer: String) -> String? {
        guard let cm = cryptoModule else { return nil }
        guard let index = self.accountsData.firstIndex(where: { $0.id == serviceID }) else { return nil }
        accountsData[index].name = newName
        accountsData[index].issuer = newIssuer
        accountsData[index].modified_date = Date()
        
        let accountObject = AccountObject(accountsData[index], cm: cm)
        try? storage.saveOrUpdateObject(object: accountObject)
        
        self.codes = getOTPList()
        return nil
    }
    
    func NoCrypt_ExportService(with id: String) -> AccountData? {
        return accountsData.first(where: { $0.id == id })
    }
    
    func NoCrypt_ExportALLService() -> [UNPROTECTED_AccountData] {
        return [] //core.NoCrypt_ExportAllServicesSECRETS()
    }
    
    /*
    init(fileURL: URL, pass: String) {
        self.storage = StorageService()
        //self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        //self.codes = core.getListOTP()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        self.loadCryptoModuleFromPassword(with: pass)
    }
    
    init() {
        self.storage = StorageService()
        // self.core = CORE_OPEN2FA()
        //// self.codes = [Account_Code(id: UUID(), date: Date(), name: "NULL INIT", issuer: "NULL ISSUER", codeSingle: "111 111")]
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        self.notificationToken = storage.realm!.observe { notification, realm in
            self.updateAccounts()
        }
    }
     */
    
    static var TestModel: Core2FA_ViewModel {
        let pass = "1234"
        
        let salt: String
        let saltKC = KeychainWrapper.shared.getSalt()
        if saltKC == nil {
            salt = CryptoModule.generateSalt()
            KeychainWrapper.shared.setSalt(salt: salt)
        } else {
            salt = saltKC!
        }
        
        let key: [UInt8]
        let keyKC = KeychainWrapper.shared.getKey()
        if  keyKC == nil {
            key = CryptoModule.generateKey(pass: pass, salt: salt)
            KeychainWrapper.shared.setKey(key: key)
        } else {
            key = keyKC!
        }
        
        let core = Core2FA_ViewModel(key: key, inMemory: true)!
        //core.storage = StorageService(inMemory: true)
        core.addAccount(name: "Test 1", issuer: "TestIssuer 1", secret: "q4qghrcn2c42bgbz")
        core.addAccount(name: "Test 2", issuer: "TestIssuer 2", secret: "q4qghrcn2c42bgbz")
        core.addAccount(name: "Test 3", issuer: "TestIssuer 3", secret: "q4qghrcn2c42bgbz")
        return core
    }
        
    init?(key: [UInt8], inMemory: Bool = false) {
        guard Core2FA_ViewModel.isKeyValid(key: key) || inMemory else { return nil }
        
        
        // IV
        var iv: [UInt8]
        let ivKC: [UInt8]? = KeychainWrapper.shared.getIV()
        if ivKC == nil {
            iv = CryptoModule.generateIV()
            KeychainWrapper.shared.setIV(iv: iv)
        } else {
            iv = ivKC!
        }
        
        self.storage = StorageService(inMemory: inMemory)
        self.cryptoModule = CryptoModule(key: key, IV: iv)
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        self.notificationToken = storage.realm!.observe { notification, realm in
            self.updateAccounts()
        }
        self.updateAccounts()
    }
    
    convenience init?(password: String, saveKey: Bool = false) {
        // Salt
        let salt: String
        let saltKC = KeychainWrapper.shared.getSalt()
        if saltKC == nil {
            salt = CryptoModule.generateSalt()
            KeychainWrapper.shared.setSalt(salt: salt)
        } else {
            salt = saltKC!
        }
        
        // Key
        let key = CryptoModule.generateKey(pass: password, salt: salt)
        if saveKey {
            KeychainWrapper.shared.setKey(key: key)
        }
        self.init(key: key)
    }
    
    deinit {
        self.timer = nil
        self.notificationToken?.invalidate()
        
        NotificationCenter.default.removeObserver(self,
            name: UIApplication.willResignActiveNotification,
            object: nil)
        
        NotificationCenter.default.removeObserver(self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        _debugPrint("DEINT")
    }
    
    func updateCore(fileURL: URL, pass: String) {
        self.setObservers()
        
       // self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = getOTPList()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
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
    }
    
    @objc func didBecomeActiveNotification() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isActive = true
        }
    }
    
    static func isPasswordValid(password: String) -> Bool {
        guard let kvc = KeychainWrapper.shared.getKVC() else { return true }
        
        // Salt
        let salt: String
        let saltKC = KeychainWrapper.shared.getSalt()
        if saltKC == nil {
            salt = CryptoModule.generateSalt()
            KeychainWrapper.shared.setSalt(salt: salt)
            _debugPrint("salt: \(salt)")
        } else {
            salt = saltKC!
        }
        
        // Key
        let key = CryptoModule.generateKey(pass: password, salt: salt)
        
        // IV
        var iv: [UInt8]
        let ivKC: [UInt8]? = KeychainWrapper.shared.getIV()
        if ivKC == nil {
            iv = CryptoModule.generateIV()
            KeychainWrapper.shared.setIV(iv: iv)
        } else {
            iv = ivKC!
        }
        
        let cryptoModule = CryptoModule(key: key, IV: iv)
        
        guard let decrypted = cryptoModule.decryptData(kvc) else { return false }
        let decoded = try? JSONDecoder().decode(AccountData.self, from: decrypted)
        _debugPrint("decoded kvc: \(decoded)")
        return decoded != nil
    }
    
    static func isKeyValid(key: [UInt8]) -> Bool {
        guard let kvc = KeychainWrapper.shared.getKVC() else { return true }
        
        // Salt
        let salt: String
        let saltKC = KeychainWrapper.shared.getSalt()
        if saltKC == nil {
            salt = CryptoModule.generateSalt()
            KeychainWrapper.shared.setSalt(salt: salt)
            _debugPrint("salt: \(salt)")
        } else {
            salt = saltKC!
        }
        
        // IV
        var iv: [UInt8]
        let ivKC: [UInt8]? = KeychainWrapper.shared.getIV()
        if ivKC == nil {
            iv = CryptoModule.generateIV()
            KeychainWrapper.shared.setIV(iv: iv)
        } else {
            iv = ivKC!
        }
        
        let cryptoModule = CryptoModule(key: key, IV: iv)
        
        guard let decrypted = cryptoModule.decryptData(kvc) else { return false }
        let decoded = try? JSONDecoder().decode(AccountData.self, from: decrypted)
        _debugPrint("decoded kvc: \(decoded)")
        return decoded != nil
    }
    
    /*
    static func checkFileO2FA(fileURL: URL, password: String) -> FUNC_RESULT {
        return CORE_OPEN2FA.checkPassword(fileURL: fileURL, password: password)
    }
     */
    
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
    
    func deleteAccount(id: String) {
        try? self.storage.deleteObjectWithId(type: AccountObject.self, id: id)
    }
    
    func fetchAccounts() -> [AccountData] {
        guard let cryptoModel = self.cryptoModule else { return [] }
        let data = storage.fetch(by: AccountObject.self).filter({ !$0.isDeleted })
        return data.compactMap({ AccountData($0, cm: cryptoModel) }).sorted()
    }
    
    func updateAccounts() {
        self.accountsData = self.fetchAccounts() // Maybe move decryption to background thread?
        self.codes = getOTPList()
    }
    
    func saveKVC() {
        guard let cryptoModel = self.cryptoModule else { return }
        let accountData = AccountData(name: NSUUID().uuidString, issuer: NSUUID().uuidString, secret: CryptoModule.generateSalt().base32DecodedData ?? Data())
        guard let encoded = try? JSONEncoder().encode(accountData) else { return }
        guard let kvc = cryptoModel.encryptData(encoded) else { return }
        
        KeychainWrapper.shared.setKVC(kvc: kvc)
    }
}
