//
//  tmp_core2fa.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

/// Legacy code with secret for 2FA generation
public struct CoreOpen2FA_AccountData: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let type: OTP_Type
    public let date: Date
    public var name: String
    public var issuer: String
    public var secret: String
    public var counter: UInt = 0
    
    public init(id: UUID = UUID(), type: OTP_Type = .TOTP, date: Date = Date(), name: String, issuer: String = "", secret: String, counter: UInt = 0) {
        self.id = id
        self.type = type
        self.date = date
        self.name = name
        self.issuer = issuer
        self.secret = secret
        self.counter = counter
    }
    
    mutating func updateHOTP() {
        self.counter += 1
    }
}

extension AccountData {
    init?(_ coreData: CoreOpen2FA_AccountData) {
        self.id = NSUUID().uuidString
        self.type = coreData.type
        self.name = coreData.name
        self.issuer = coreData.issuer
        guard let secret = coreData.secret.base32DecodedData else { return nil }
        self.secret = secret
        self.counter = coreData.counter
        self.creation_date = coreData.date
        self.modified_date = self.creation_date
    }
}
