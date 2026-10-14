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

// MARK: - AccountObject
class AccountObject: Object {
    @Persisted(primaryKey: true) var id = NSUUID().uuidString
    @Persisted var iv: Data
    @Persisted var account_data: Data?
    /// 1 = CryptoSwift GCM (16-byte IV), 2 = CryptoKit GCM (12-byte nonce).
    @Persisted var cipherVersion: Int = 1
    
    /// IceCream safe delete
    @Persisted var isDeleted = false
}

class VaultMigrationWrap: Object {
    static let singletonID = "wrap"

    @Persisted(primaryKey: true) var id = "wrap"
    @Persisted var salt = ""
    @Persisted var ivKVC = Data()
    @Persisted var kvc = Data()
    @Persisted var paramsJSON = Data()
    @Persisted var wrappedKey = Data()
    @Persisted var wrapIV = Data()
    @Persisted var wrapCipherVersion = 2
}

extension AccountObject {
    convenience init(_ dto: AccountData, cm: CryptoService) {
        self.init()
        self.id = dto.id
        self.cipherVersion = KDFParams.current.cipherVersion
        guard let encoded = try? JSONEncoder().encode(dto),
              let sealed = try? cm.encrypt(plaintext: encoded) else {
            self.iv = Data()
            self.account_data = nil
            return
        }
        self.iv = sealed.iv
        self.account_data = sealed.ciphertext
    }
}

extension AccountObject: CKSafeDelete & CKRecordConvertible & CKRecordRecoverable { }

protocol CKSafeDelete {
    var isDeleted: Bool { get set }
}
