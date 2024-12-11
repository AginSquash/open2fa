//
//  AccountCurrentCode.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

// MARK: - OTP_Type
public enum OTP_Type: Codable, Sendable {
    case TOTP
    case HOTP
}

// MARK: - AccountCurrentCode
struct AccountCurrentCode: Identifiable, Hashable, Sendable {
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
