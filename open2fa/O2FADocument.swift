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
