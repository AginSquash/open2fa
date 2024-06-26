//
//  CloudService.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitService {
    private static let accountObjectZoneName: String = "AccountObjectsZone"
    private static let objectRecordName: String = "AccountObject"

    static func checkAccountStatus() async throws -> CKAccountStatus {
        try await CKContainer.default().accountStatus()
    }
    
    static func save(_ record: CKRecord) async throws {
        try await CKContainer.default().privateCloudDatabase.save(record)
    }
    
    static private func fecth(recordType: String, zoneID: CKRecordZone.ID? = nil) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await CKContainer.default().privateCloudDatabase.records(matching: query, inZoneWith: zoneID, desiredKeys: nil)
        return result.matchResults.compactMap({ try? $0.1.get() })
    }
    
    static func deleteAllAccounts() async throws {
        let zone = CKRecordZone(zoneName: CloudKitService.accountObjectZoneName)
        let records = try await CloudKitService.fecth(recordType: objectRecordName, zoneID: zone.zoneID)
        let ids = records.map { $0.recordID }
        _ = try await CKContainer.default().privateCloudDatabase.modifyRecords(saving: [], deleting: ids)
    }
    
    // MARK: - PublicEncryptData CRD
    static func fetchPublicEncryptData() async throws -> [PublicEncryptData] {
        let records = try await self.fecth(recordType: PublicEncryptData.RecordKeys.type.rawValue)
        return records.compactMap(PublicEncryptData.init)
    }
    
    static func uploadPublicEncryptData() async throws {
        guard let kvc = KeychainService.shared.getKVC() else { return  }
        guard let salt = KeychainService.shared.getSalt() else { return }
        guard let iv = KeychainService.shared.getIV_KVC() else { return }

        let publicED = PublicEncryptData(salt: salt, iv_kvc: iv, kvc: kvc)
        try await CloudKitService.save(publicED.record)
    }
    
    static func deleteAllPublicEncryptData() async throws {
        let records = try await self.fecth(recordType:  PublicEncryptData.RecordKeys.type.rawValue)
        let ids = records.map { $0.recordID }
        _ = try await CKContainer.default().privateCloudDatabase.modifyRecords(saving: [], deleting: ids)
    }
    
    
    // Not used rn
    static func createZone() {
        let cloudContainer = CKContainer.default()
        let privateDatabase = cloudContainer.privateCloudDatabase
        let zone = CKRecordZone(zoneName: CloudKitService.accountObjectZoneName)
        let saveOperation = CKModifyRecordZonesOperation(recordZonesToSave: [zone])
        privateDatabase.add(saveOperation)
    }
    
    static func deleteZone() {
        let cloudContainer = CKContainer.default()
        let privateDatabase = cloudContainer.privateCloudDatabase
        let zone = CKRecordZone(zoneName: CloudKitService.accountObjectZoneName)
        let deleteOperation = CKModifyRecordZonesOperation(recordZoneIDsToDelete: [zone.zoneID])
        privateDatabase.add(deleteOperation)
    }
}
