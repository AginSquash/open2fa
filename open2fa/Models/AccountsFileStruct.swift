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
    let accounts: Data?
    
    init(publicEncryptData: PublicEncryptData, accounts: Data?) {
        self.core_version = "7.0.0"
        self.publicEncryptData = publicEncryptData
        self.accounts = accounts
    }
}
