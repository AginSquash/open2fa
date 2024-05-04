//
//  O2FADocument.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 26.10.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct CodesFile_legacy: Codable {
    var core_version: String
    var IV: String
    var passcheck: Data?
    var codes: Data?
}

struct O2FADocument: FileDocument {
    static var readableContentTypes: [UTType] = [UTType(filenameExtension: "o2fa")!]
    
    var accountsFileStruct: AccountsFileStruct
    
    init(accountsFileStruct: AccountsFileStruct) {
        self.accountsFileStruct = accountsFileStruct
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let accountsFileStruct = try? JSONDecoder().decode(AccountsFileStruct.self, from: data)
            else {
                throw CocoaError(.fileReadCorruptFile)
        }
        
        self.accountsFileStruct = accountsFileStruct
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoded = try! JSONEncoder().encode(accountsFileStruct)
        return FileWrapper(regularFileWithContents: encoded)
    }
    
}


struct O2FA_Unencrypted: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var accountsUnencrypted: [CoreOpen2FA_AccountData]
    
    init(accounts: [CoreOpen2FA_AccountData]) {
        self.accountsUnencrypted = accounts
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let accounts = try? JSONDecoder().decode([CoreOpen2FA_AccountData].self, from: data)
            else {
                throw CocoaError(.fileReadCorruptFile)
        }
        
        accountsUnencrypted = accounts
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let jsonData = try JSONEncoder().encode(self.accountsUnencrypted)
        return FileWrapper(regularFileWithContents: jsonData)
    }
    
}
