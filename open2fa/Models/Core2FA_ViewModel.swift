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

    @Published var accountData = [AccountData]()
    //var testCloud: [AccountObject] = StorageService.sharedInstance.fetch(by: AccountObject.self)
    
    var token: NotificationToken?

    /// Realm
    private var storage: StorageService
    var notificationToken: NotificationToken?
    
    /// Crypto
    private var cryptoModule: CryptoModule?
    
    private var timer: Timer?
    
    let cloudContainer = CKContainer.default()
    
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
        for account in accountData {
            guard let totp = TOTP(secret: account.secret) else { continue }
            guard let currentCode = totp.generate(time: Date()) else { continue }
            let newACC = AccountCurrentCode(account, currentCode: currentCode)
            accountsCurrentCode.append(newACC)
        }
        return accountsCurrentCode
    }
    
    func deleteService(uuid: String) {
        /*
        guard self.core.DeleteAccount(id: uuid) == .SUCCEFULL else {
            fatalError("DeleteCode error")
        }
        withAnimation {
            self.codes.removeAll(where: { $0.id == uuid } )
        }
         */
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
        guard let baase32Decoded = secret.base32DecodedData else { return nil }
        
        let newAccount = AccountData(name: name, issuer: issuer, secret: baase32Decoded)
        let accountObject = AccountObject(newAccount, cm: cm)
        try? storage.saveOrUpdateObject(object: accountObject)
        
        self.accountData.append(newAccount)
        self.codes = getOTPList()
        
        return nil
        /*
        let result = core.AddAccount(account_name: name, issuer: issuer, secret: secret)
        if result == .SUCCEFULL {
            self.codes = self.core.getListOTP()
            return nil
        }
        
        switch result {
        case .ALREADY_EXIST:
            return "This name already taken"
        case .CODE_INCORRECT:
            return "This code is incorrect"
        default:
            return "Unknown error"
        }
         */
    }
    
    func editAccount(serviceID: String, newName: String, newIssuer: String) -> String? {
        /*
        let result = core.EditAccount(id: serviceID, newName: newName, newIssuer: newIssuer)
        if result == .SUCCEFULL {
            self.codes = self.core.getListOTP()
            return nil
        }
        
        switch result {
        case .ALREADY_EXIST:
            return "This name already taken"
        case .CANNOT_FIND_ID:
            return "Cannot find this ID"
        default:
            return "Unknown error"
        }
         */
        return nil
    }
    
    func NoCrypt_ExportService(with id: UUID) -> UNPROTECTED_AccountData? {
        return nil //core.NoCrypt_ExportServiceSECRET(with: id)
    }
    
    func NoCrypt_ExportALLService() -> [UNPROTECTED_AccountData] {
        return [] //core.NoCrypt_ExportAllServicesSECRETS()
    }
    
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
        self.token = storage.realm!.observe { notification, realm in
            self.updateAccounts()
        }
    }
    
    deinit {
        self.timer = nil
        self.token?.invalidate()
        
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
    
    static func isPasswordCorrect(fileURL: URL, password: String) -> Bool {
        return true
        
        /*
        let passcheck = CORE_OPEN2FA.checkPassword(fileURL: fileURL, password: password)
        switch passcheck {
        case .PASS_INCORRECT:
            _debugPrint("PASS_INCORRECT")
            break
        case .FILE_NOT_EXIST:
            _debugPrint("FILE_NOT_EXIST")
            break
        case .CANNOT_DECODE:
            _debugPrint("CANNOT_DECODE")
            break
        case .FILE_UNVIABLE:
            _debugPrint("FILE_UNVIABLE")
            break
        case .NO_CODES:
            _debugPrint("NO_CODES")
            break
        case .SUCCEFULL:
            break
        default:
            _debugPrint("no one")
        }
        return passcheck == .SUCCEFULL || passcheck == .NO_CODES
         */
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
    
    func TEST_addNewRecord() {
        guard let cryptoModel = self.cryptoModule else { return }
        let newRecord = AccountData() //AccountDTO(id: NSUUID().uuidString, account_data: nil)
        let object = AccountObject(newRecord, cm: cryptoModel)
        try? storage.saveOrUpdateObject(object: object)
    }
    
    func TEST_readDB() {
        guard let cryptoModel = self.cryptoModule else { return }
        let data = storage.fetch(by: AccountObject.self)
        let map = data.map({ AccountData($0, cm: cryptoModel) })
        print("DEBUG: readed from DB: \(map)")
    }
    
    func deleteAccount(id: String) {
        _debugPrint("trying to delete \(id)")
        try? self.storage.deleteObjectWithId(type: AccountObject.self, id: id)
    }
    
    func fetchAccounts() -> [AccountData] {
        guard let cryptoModel = self.cryptoModule else { return [] }
        let data = storage.fetch(by: AccountObject.self).filter({ !$0.isDeleted })
        return data.map({ AccountData($0, cm: cryptoModel) })
    }
    
    func updateAccounts() {
        self.accountData = self.fetchAccounts() // Maybe move decryption to background thread?
    }
}

//MARK: - Crypto module
extension Core2FA_ViewModel {
    
    func loadCryptoModuleFromPassword(with pass: String) {
        let salt: String
        let saltKC = KeychainWrapper.shared.getSalt()
        if saltKC == nil {
            salt = CryptoModule.generateSalt()
            KeychainWrapper.shared.setSalt(salt: salt)
            _debugPrint("salt: \(salt)")
        } else {
            salt = saltKC!
        }
        
        let key = CryptoModule.generateKey(pass: pass, salt: salt)
        initCryptoModule(key: key)
    }
    
    func loadCryptoModuleFromKeychain() {
        guard let key = KeychainWrapper.shared.getKey() else {
            // must return something
            return
        }
        
        initCryptoModule(key: [UInt8](key))
    }
    
    private func initCryptoModule(key: [UInt8]) {
        var iv: [UInt8]
        let ivKC: [UInt8]? = KeychainWrapper.shared.getIV()
        if ivKC == nil {
            iv = CryptoModule.generateIV()
            KeychainWrapper.shared.setIV(iv: iv)
        } else {
            iv = ivKC!
        }
        
        _debugPrint("saved iv: \(KeychainWrapper.shared.getIV())\n saved salt: \( KeychainWrapper.shared.getSalt())")
        self.cryptoModule = CryptoModule(key: key, IV: iv)
        self.updateAccounts()
    }
}
