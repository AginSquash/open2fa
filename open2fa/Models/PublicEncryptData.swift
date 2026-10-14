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
        case kvc
        case iv_kvc
        case kdfVersion
        case kdfIterations
        case cipherVersion
        case saltIsBase64
    }

    let salt: String
    let iv_kvc: [UInt8]
    let kvc: Data
    var kdfVersion: Int
    var kdfIterations: Int
    var cipherVersion: Int
    var saltIsBase64: Bool

    enum CodingKeys: String, CodingKey {
        case salt
        case kvc
        case iv_kvc
        case kdfVersion
        case kdfIterations
        case cipherVersion
        case saltIsBase64
    }

    var kdfParams: KDFParams {
        KDFParams(
            version: kdfVersion,
            iterations: kdfIterations,
            cipherVersion: cipherVersion,
            saltIsBase64: saltIsBase64
        )
    }

    init(salt: String, iv_kvc: [UInt8], kvc: Data, params: KDFParams = .legacy) {
        self.salt = salt
        self.iv_kvc = iv_kvc
        self.kvc = kvc
        self.kdfVersion = params.version
        self.kdfIterations = params.iterations
        self.cipherVersion = params.cipherVersion
        self.saltIsBase64 = params.saltIsBase64
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        salt = try container.decode(String.self, forKey: .salt)
        iv_kvc = try container.decode([UInt8].self, forKey: .iv_kvc)
        kvc = try container.decode(Data.self, forKey: .kvc)
        kdfVersion = try container.decodeIfPresent(Int.self, forKey: .kdfVersion) ?? KDFParams.legacy.version
        kdfIterations = try container.decodeIfPresent(Int.self, forKey: .kdfIterations) ?? KDFParams.legacy.iterations
        cipherVersion = try container.decodeIfPresent(Int.self, forKey: .cipherVersion) ?? KDFParams.legacy.cipherVersion
        saltIsBase64 = try container.decodeIfPresent(Bool.self, forKey: .saltIsBase64) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(salt, forKey: .salt)
        try container.encode(iv_kvc, forKey: .iv_kvc)
        try container.encode(kvc, forKey: .kvc)
        try container.encode(kdfVersion, forKey: .kdfVersion)
        try container.encode(kdfIterations, forKey: .kdfIterations)
        try container.encode(cipherVersion, forKey: .cipherVersion)
        try container.encode(saltIsBase64, forKey: .saltIsBase64)
    }
}

extension PublicEncryptData {
    var record: CKRecord {
        let record = CKRecord(recordType: Self.RecordKeys.type.rawValue)
        record[Self.RecordKeys.salt.rawValue] = salt
        record[Self.RecordKeys.iv_kvc.rawValue] = iv_kvc
        record[Self.RecordKeys.kvc.rawValue] = kvc
        record[Self.RecordKeys.kdfVersion.rawValue] = kdfVersion as NSNumber
        record[Self.RecordKeys.kdfIterations.rawValue] = kdfIterations as NSNumber
        record[Self.RecordKeys.cipherVersion.rawValue] = cipherVersion as NSNumber
        record[Self.RecordKeys.saltIsBase64.rawValue] = saltIsBase64 as NSNumber
        return record
    }
}

extension PublicEncryptData {
    init?(from record: CKRecord) {
        guard
            let salt = record[Self.RecordKeys.salt.rawValue] as? String,
            let iv = record[Self.RecordKeys.iv_kvc.rawValue] as? [UInt8],
            let kvc = record[Self.RecordKeys.kvc.rawValue] as? Data
        else { return nil }
        let params = KDFParams(
            version: (record[Self.RecordKeys.kdfVersion.rawValue] as? NSNumber)?.intValue ?? KDFParams.legacy.version,
            iterations: (record[Self.RecordKeys.kdfIterations.rawValue] as? NSNumber)?.intValue ?? KDFParams.legacy.iterations,
            cipherVersion: (record[Self.RecordKeys.cipherVersion.rawValue] as? NSNumber)?.intValue ?? KDFParams.legacy.cipherVersion,
            saltIsBase64: (record[Self.RecordKeys.saltIsBase64.rawValue] as? NSNumber)?.boolValue ?? false
        )
        guard KDFParams.isAllowed(params) else { return nil }
        self.init(salt: salt, iv_kvc: iv, kvc: kvc, params: params)
    }
}
