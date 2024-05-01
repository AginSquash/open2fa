//
//  ImportExportModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 01.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

class ImportExportModel {
    
    func getAccounts(from data: Data, pass: String) {
        if let decoded = try? JSONDecoder().decode(CodesFile_legacy.self, from: data) {
            
        }
    }
    
    private func legacyDecrypt(pass: String) {
        
    }
}
