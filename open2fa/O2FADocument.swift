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
import core_open2fa

struct codesFile: Codable {
    var core_version: String
    var IV: String
    var passcheck: Data?
    var codes: Data?
}

struct O2FADocument: FileDocument {
    static var readableContentTypes: [UTType] = [UTType(filenameExtension: "o2fa")!]
    
    var cf: codesFile
    
    init(url: URL) {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.cf = codesFile(core_version: "3.0", IV: "IV", passcheck: nil, codes: nil)
            return
        }
        
        let data = try! Data(contentsOf: url)
        let decoded = try! JSONDecoder().decode(codesFile.self, from: data)
        self.cf = decoded
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let codesFile = try? JSONDecoder().decode(codesFile.self, from: data)
            else {
                throw CocoaError(.fileReadCorruptFile)
        }
        
       cf = codesFile
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoded = try! JSONEncoder().encode(cf)
        return FileWrapper(regularFileWithContents: encoded)
    }
    
}


struct O2FA_Unencrypted: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var accountsUnencrypted: [UNPROTECTED_AccountData]
    
    init(accounts: [UNPROTECTED_AccountData]) {
        self.accountsUnencrypted = accounts
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let accounts = try? JSONDecoder().decode([UNPROTECTED_AccountData].self, from: data)
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
