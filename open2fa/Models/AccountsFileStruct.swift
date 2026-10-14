//
//  AccountsFileStruct.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 01.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

struct AccountsFileStruct: Codable {
    let core_version: String
    let publicEncryptData: PublicEncryptData
    let iv: [UInt8]
    let accounts: Data?
    /// Absent in v7 files. Those blobs are CryptoSwift GCM.
    let accountsCipherVersion: Int?

    init(publicEncryptData: PublicEncryptData, iv: [UInt8], accounts: Data?, accountsCipherVersion: Int) {
        self.core_version = accountsCipherVersion >= KDFParams.current.cipherVersion ? "8.0.0" : "7.0.0"
        self.publicEncryptData = publicEncryptData
        self.iv = iv
        self.accounts = accounts
        self.accountsCipherVersion = accountsCipherVersion
    }
}
