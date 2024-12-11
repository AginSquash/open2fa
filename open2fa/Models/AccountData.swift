//
//  AccountData.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//
import Foundation

// MARK: - AccountData
struct AccountData: Codable, Identifiable {
    let id: String
    let type: OTP_Type
    var name: String
    var issuer: String
    var secret: Data
    var counter: UInt = 0
    var creation_date: Date
    var modified_date: Date
}

extension AccountData: Comparable {
    static func < (lhs: AccountData, rhs: AccountData) -> Bool {
        return lhs.creation_date < rhs.creation_date
    }
}

extension AccountData {
    init(name: String, issuer: String, secret: Data) {
        self.id = NSUUID().uuidString
        self.type = .TOTP
        self.name = name
        self.issuer = issuer
        self.secret = secret
        self.counter = 0
        self.creation_date = Date()
        self.modified_date = self.creation_date
    }
    
    init?(_ object: AccountObject, cm: CryptoService) {
        guard let data = object.account_data else { return nil }
        let iv = [UInt8](object.iv)
        guard let decrypted = cm.decryptData(iv: iv, inputData: data),
              let decoded = try? JSONDecoder().decode(AccountData.self, from: decrypted) else { return nil }
        self = decoded
    }
}
