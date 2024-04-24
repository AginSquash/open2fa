//
//  AccountModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 22.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import RealmSwift
import IceCream

// MARK: - OTP_Type
public enum OTP_Type: Codable {
    case TOTP
    case HOTP
}

// MARK: - AccountCurrentCode
struct AccountCurrentCode: Identifiable {
    let id: String
    let type: OTP_Type
    let name: String
    let issuer: String
    let currentCode: String
    let creation_date: Date
}

extension AccountCurrentCode: Comparable {
    static func < (lhs: AccountCurrentCode, rhs: AccountCurrentCode) -> Bool {
        return lhs.creation_date < rhs.creation_date
    }
}

extension AccountCurrentCode {
    init(_ accountData: AccountData, currentCode: String) {
        self.id = accountData.id
        self.type = accountData.type
        self.name = accountData.name
        self.issuer = accountData.issuer
        self.creation_date = accountData.creation_date
        self.currentCode = currentCode
    }
}

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

extension AccountData {
    init() {
        id = NSUUID().uuidString
        type = .TOTP
        name = "Test 1"
        issuer = "issuer"
        secret = "secret".base32DecodedData!
        counter = 0
        creation_date = Date()
        modified_date = Date()
    }
    
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
    
    init(_ object: AccountObject, cm: CryptoModule) {
        guard let data = object.account_data else { self.init(); return }
        guard let decrypted = cm.decryptData(data) else { self.init(); return }
        guard let decoded = try? JSONDecoder().decode(AccountData.self, from: decrypted) else { self.init(); return }
        self = decoded
    }
}

// MARK: - AccountObject
class AccountObject: Object {
    @Persisted(primaryKey: true) var id = NSUUID().uuidString
    @Persisted var account_data: Data?
    
    /// IceCream safe delete
    @Persisted var isDeleted = false
}

extension AccountObject {
    convenience init(_ dto: AccountData, cm: CryptoModule) {
        self.init()
        self.id = dto.id
        guard let encoded = try? JSONEncoder().encode(dto) else { self.account_data = nil; return }
        self.account_data = cm.encryptData(encoded)
    }
}

extension AccountObject: CKSafeDelete & CKRecordConvertible & CKRecordRecoverable { }

protocol CKSafeDelete {
    var isDeleted: Bool { get set }
}
