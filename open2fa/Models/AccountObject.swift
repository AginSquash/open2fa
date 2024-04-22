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
    public let type: OTP_Type
    public var name: String
    public var issuer: String
    public var secret: String
    public var counter: UInt = 0
}

class AccountObject: Object {
    @Persisted(primaryKey: true) var id = NSUUID().uuidString
    @Persisted var creation_date: Date
    @Persisted var modified_date: Date
    @Persisted var account_data: String
    
    /// IceCream safe delete
    @Persisted var isDeleted = false
}

extension AccountObject: CKRecordConvertible & CKRecordRecoverable {

}

extension AccountObject{
    convenience init(_ dto: AccountDTO) {
        self.init()
        self.id = dto.id
        self.creation_date = dto.creation_date
        self.modified_date = dto.modified_date
        self.account_data = dto.account_data
    }
}

struct AccountDTO {
    let id: String
    let creation_date: Date
    var modified_date: Date
    var account_data: String
}

extension AccountDTO {
    init(object: AccountObject) {
        id = object.id
        creation_date = object.creation_date
        modified_date = object.modified_date
        account_data = object.account_data
    }
}
