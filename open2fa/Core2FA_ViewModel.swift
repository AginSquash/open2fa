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
import core_open2fa
import GAuthDecrypt

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

class Core2FA_ViewModel: ObservableObject
{
    
    @Published var codes: [Account_Code]
    @Published var timeRemaning: Int = 0
    @Published var isActive: Bool = true
    @Published var progress: CGFloat = 1.0
    
    private var core: CORE_OPEN2FA
    private var timer: Timer?
    
    
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
    
    init(fileURL: URL, pass: String) {
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = core.getListOTP()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    
    init() {
        self.core = CORE_OPEN2FA()
        self.codes = [Account_Code(id: UUID(), date: Date(), name: "NULL INIT", issuer: "NULL ISSUER", codeSingle: "111 111")]
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    deinit {
        self.timer = nil
        
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
    
}
