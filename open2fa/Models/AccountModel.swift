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
    
    /// IceCream safe delete
    @Persisted var isDeleted = false
}

extension AccountObject {
    convenience init(_ dto: AccountData, cm: CryptoService) {
        self.init()
        self.id = dto.id
        let iv = CryptoService.generateIV()
        self.iv = Data(iv)
        guard let encoded = try? JSONEncoder().encode(dto) else { self.account_data = nil; return }
        self.account_data = cm.encryptData(iv: iv, inputData: encoded)
    }
}

extension AccountObject: CKSafeDelete & CKRecordConvertible & CKRecordRecoverable { }

protocol CKSafeDelete {
    var isDeleted: Bool { get set }
}
