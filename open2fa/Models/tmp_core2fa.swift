//
//  tmp_core2fa.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

/// Code with secret for 2FA generation
public struct UNPROTECTED_AccountData: Identifiable, Codable, Equatable {
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
