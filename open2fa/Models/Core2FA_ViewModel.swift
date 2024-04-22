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
import core_open2fa
import CloudKit
import RealmSwift

extension String {
    init(_ func_result: FUNC_RESULT) {
        switch func_result {
        case .SUCCEFULL:
            self = "SUCCEFULL"
        default:
            self = "OTHER"
        }
    }
}

class Core2FA_ViewModel: ObservableObject {
    
    @Published var codes: [Account_Code]
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
    private var cryptoModel: CryptoModule?
    
    private var core: CORE_OPEN2FA
    private var timer: Timer?
    
    let cloudContainer = CKContainer.default()
    private lazy var database = cloudContainer.privateCloudDatabase
    
    let recordID: CKRecord.ID = .init(recordName: "encrypted.o2fa")
    
    @objc func updateTime() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "ss"
        let time = Int(df.string(from: date))!
        
        if (time == 0 || time == 30) {
            self.codes = self.core.getListOTP()
        }
        
        if time > 30 {
            timeRemaning = 60 - time
        } else {
            timeRemaning = 30 - time
        }
        
        progress = CGFloat( Double(timeRemaning) / 30 )
    }
    
    func deleteService(uuid: UUID) {
        guard self.core.DeleteAccount(id: uuid) == .SUCCEFULL else {
            fatalError("DeleteCode error")
        }
        withAnimation {
            self.codes.removeAll(where: { $0.id == uuid } )
        }
    }
    
    func DEBUG() {
        _ = core.AddAccount(account_name: "Test1", issuer: "Google", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test2", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test3", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test4", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test5", secret: "q4qghrcn2c42bgbz")
        _ = core.AddAccount(account_name: "Test6_extralargenamewillbehere", issuer: "CompanyWExtraLargeName", secret: "q4qghrcn2c42bgbz")
    }
    
    func addAccount(name: String, issuer: String, secret: String) -> String? {
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
    }
    
    func editAccount(serviceID: UUID, newName: String, newIssuer: String) -> String? {
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
    }
    
    func NoCrypt_ExportService(with id: UUID) -> UNPROTECTED_AccountData? {
        return core.NoCrypt_ExportServiceSECRET(with: id)
    }
    
    func NoCrypt_ExportALLService() -> [UNPROTECTED_AccountData] {
        return core.NoCrypt_ExportAllServicesSECRETS()
    }
    
    func loadCryptoModule(with pass: String) {
       // DispatchQueue.global(qos: .userInitiated).async {
            let key: [UInt8]
            let salt: String
        
        /*
            let saltKC = KeychainWrapper.sharedInstance.getString(name: .salt)
            if saltKC == nil {
                salt = CryptoModule.generateSalt()
                KeychainWrapper.sharedInstance.setValue(name: .salt, value: salt)
                _debugPrint("salt: \(salt)")
            } else {
                salt = saltKC!
            }
            
            key = CryptoModule.generateKey(pass: pass, salt: salt)
        */
            
             var keyKC: Data? = KeychainWrapper.sharedInstance.getValue(name: .key)
             if keyKC == nil {
             let salt = KeychainWrapper.sharedInstance.getString(name: .salt) ?? CryptoModule.generateSalt()
             _debugPrint("salt: \(salt)")
             key = CryptoModule.generateKey(pass: pass, salt: salt)
             KeychainWrapper.sharedInstance.setValue(name: .key, value: key)
             KeychainWrapper.sharedInstance.setValue(name: .salt, value: salt)
             } else {
                 key = [UInt8](keyKC!)
             }
             
            
            var iv: [UInt8]
            let ivKC: Data? = KeychainWrapper.sharedInstance.getValue(name: .iv)
            if ivKC == nil {
                iv = CryptoModule.generateIV()
                KeychainWrapper.sharedInstance.setValue(name: .iv, value: iv)
            } else {
                iv = [UInt8](ivKC!)
            }
            
            //DispatchQueue.main.async {
                self.cryptoModel = CryptoModule(key: key, IV: iv)
                self.updateAccounts()
                _debugPrint("cryptoModel created with: key \(key), iv: \(iv)")
           // }
       // }
        /*
        self.cryptoModel = CryptoModule(key: key, IV: iv)
        self.updateAccounts()
        _debugPrint("cryptoModel created with: key \(key), iv: \(iv)")
         */
    }
    
    init(fileURL: URL, pass: String) {
        self.storage = StorageService()
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = core.getListOTP()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        self.loadCryptoModule(with: pass)
    }
    
    init() {
        self.storage = StorageService()
        self.core = CORE_OPEN2FA()
        self.codes = [Account_Code(id: UUID(), date: Date(), name: "NULL INIT", issuer: "NULL ISSUER", codeSingle: "111 111")]
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
        
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = core.getListOTP() 
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
    }
    
    static func checkFileO2FA(fileURL: URL, password: String) -> FUNC_RESULT {
        return CORE_OPEN2FA.checkPassword(fileURL: fileURL, password: password)
    }
    
    func importFromGAuth(gauthString: String) -> Int {
     guard let decryprtedGAuth = GAuthDecryptFrom(string: gauthString) else {
            return 0
        }
        
        var newAccounts = [UNPROTECTED_AccountData]()
        for decrypted in decryprtedGAuth {
            if decrypted.type == .hotp {
                return 0
            }
            newAccounts.append(UNPROTECTED_AccountData(name: decrypted.name, issuer: decrypted.issuer, secret: decrypted.secret))
        }
        let result = core.AddMulipleAccounts(newAccounts: newAccounts)
        
        _debugPrint("result: \(result)")
        
        self.codes = self.core.getListOTP()
        
        return result
    }
    
    func uploadDataToCloud() async throws {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("encrypted.o2fa")
        let data = try! Data(contentsOf: fileURL)
        
        let storeDataRecord = CKRecord(recordType: "open2faFile", recordID: recordID)
        storeDataRecord["data"] = data as CKRecordValue
        
        let recordResult: Result<CKRecord, Error>
            // With the CloudKit async API, we can customize savePolicy. (For this sample, we'd like
            // to overwrite the server version of the record in all cases, regardless of what's
            // on the server.
        do {
            let (saveResults, _) = try await database.modifyRecords(saving: [storeDataRecord],
                                                                    deleting: [],
                                                                    savePolicy: .allKeys)
            // In this sample, we will only ever be saving a single record,
            // so we only expect one returned result.  We know that if the
            // function did not throw, we'll have a result for every record
            // we attempted to save
            recordResult = saveResults[recordID]!
        } catch let functionError { // Handle per-function error
            // Give callers a chance to handle this error as they like
            throw functionError
        }
        /// The CloudKit container to use. Update with your own container identifier.
      
        switch recordResult {
        case .success(let savedRecord):
            print("DEBUG: saved \(savedRecord)")
            break
        case .failure(let recordError): // Handle per-record error
            // Give callers a chance to handle this error as they like
            //throw recordError
            fatalError(recordError.localizedDescription)
        }
    }
    
    /// Fetches the store data record
    func loadCloudStoreData() async throws {
        // Here, we will use the convenience async method on CKDatabase
        // to fetch a single CKRecord
        do {
            let record = try await database.record(for: recordID)
            if let storeJson = record["data"] as? Data {
                core.loadNewFileFromData(newData: storeJson)
                self.codes = core.getListOTP()
            }
            
        } catch {
            // Give callers a chance to handle this error as they like
            throw error
        }
    }
    
    let iv = "ZRhF3P6KXVzT9jed"
    
    func TEST_addNewRecord() {
        guard let cryptoModel = self.cryptoModel else { return }
        let newRecord = AccountData() //AccountDTO(id: NSUUID().uuidString, account_data: nil)
        let object = AccountObject(newRecord, cm: cryptoModel)
        try? storage.saveOrUpdateObject(object: object)
    }
    
    func TEST_readDB() {
        guard let cryptoModel = self.cryptoModel else { return }
        let data = storage.fetch(by: AccountObject.self)
        let map = data.map({ AccountData($0, cm: cryptoModel) })
        print("DEBUG: readed from DB: \(map)")
    }
    
    func fetchAccounts() -> [AccountData] {
        guard let cryptoModel = self.cryptoModel else { return [] }
        let data = storage.fetch(by: AccountObject.self)
        return data.map({ AccountData($0, cm: cryptoModel) })
    }
    
    func updateAccounts() {
        self.accountData = self.fetchAccounts() // Maybe move decryption to background thread?
    }
}
