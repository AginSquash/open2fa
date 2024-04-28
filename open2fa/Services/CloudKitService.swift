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
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        try await CKContainer.default().accountStatus()
    }
    
    func save(_ record: CKRecord) async throws {
        try await CKContainer.default().privateCloudDatabase.save(record)
    }
        
    func fetchPublicEncryptData() async throws -> [PublicEncryptData] {
        let records = try await self.fecth(recordType: PublicEncryptData.RecordKeys.type.rawValue)
        return records.compactMap(PublicEncryptData.init)
    }
    
    private func fecth(recordType: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await CKContainer.default().privateCloudDatabase.records(matching: query)
        return result.matchResults.compactMap({ try? $0.1.get() })
    }
    
    func removeAllPublicEncryptData() async throws {
        let records = try await self.fecth(recordType:  PublicEncryptData.RecordKeys.type.rawValue)
        let ids = records.map { $0.recordID }
        _ = try await CKContainer.default().privateCloudDatabase.modifyRecords(saving: [], deleting: ids)
    }
}
