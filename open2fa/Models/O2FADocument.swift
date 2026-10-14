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
    static var readableContentTypes: [UTType] {
        [UTType(filenameExtension: "o2fa")!]
    }
    
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
        let encoded = try JSONEncoder().encode(accountsFileStruct)
        return FileWrapper(regularFileWithContents: encoded)
    }
}
