//
//  PublicEncryptData.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 28.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CloudKit

struct PublicEncryptData: Hashable, Codable {
    enum RecordKeys: String {
        case type = "PublicEncryptData"
        case salt
        case iv
        case kvc
    }
    
    let salt: String
    let iv: [UInt8]
    let kvc: Data
}

extension PublicEncryptData {
    var record: CKRecord {
        let record = CKRecord(recordType: Self.RecordKeys.type.rawValue)
        record[Self.RecordKeys.salt.rawValue] = salt
        record[Self.RecordKeys.iv.rawValue] = iv
        record[Self.RecordKeys.kvc.rawValue] = kvc
        return record
    }
}

extension PublicEncryptData {
    init?(from record: CKRecord) {
        guard
            let salt = record[Self.RecordKeys.salt.rawValue] as? String,
            let iv = record[Self.RecordKeys.iv.rawValue] as? [UInt8],
            let kvc = record[Self.RecordKeys.kvc.rawValue] as? Data
        else { return nil }
        self = .init(salt: salt, iv: iv, kvc: kvc)
    }
}
