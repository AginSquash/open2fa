//
//  CloudService.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CloudKit

class CloudService {
    private static let zoneName: String = "AccountObjectsZone"
    
    static func createZone() {
        let cloudContainer = CKContainer.default()
        let privateDatabase = cloudContainer.privateCloudDatabase
        let zone = CKRecordZone(zoneName: CloudService.zoneName)
        let saveOperation = CKModifyRecordZonesOperation(recordZonesToSave: [zone])
        privateDatabase.add(saveOperation)
    }
    
    static func deleteZone() {
        let cloudContainer = CKContainer.default()
        let privateDatabase = cloudContainer.privateCloudDatabase
        let zone = CKRecordZone(zoneName: CloudService.zoneName)
        let deleteOperation = CKModifyRecordZonesOperation(recordZoneIDsToDelete: [zone.zoneID])
        privateDatabase.add(deleteOperation)
    }
}
