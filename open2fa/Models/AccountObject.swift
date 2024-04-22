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

enum OTP_Type: Codable {
    case TOTP
    case HOTP
}

struct AccountData: Codable {
    let id: String
    let type: OTP_Type
    var name: String
    var issuer: String
    var secret: String
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
        secret = "secret"
        counter = 0
        creation_date = Date()
        modified_date = Date()
    }
    
    init(_ object: AccountObject) {
        self.init(data: object.account_data)
    }
    
    init(data: Data?) {
        guard let data = data else { self.init(); return }
        guard let decoded = try? JSONDecoder().decode(AccountData.self, from: data) else { self.init(); return }
        self = decoded
    }
}

class AccountObject: Object {
    @Persisted(primaryKey: true) var id = NSUUID().uuidString
    @Persisted var account_data: Data?
    
    /// IceCream safe delete
    @Persisted var isDeleted = false
}

extension AccountObject: CKRecordConvertible & CKRecordRecoverable {

}

extension AccountObject {
    convenience init(_ dto: AccountData) {
        self.init()
        self.id = dto.id
        let encoded = try? JSONEncoder().encode(dto)
        self.account_data = encoded
        
    }
}
