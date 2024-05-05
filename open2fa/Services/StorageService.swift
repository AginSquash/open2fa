//
//  StorageService.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 22.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import RealmSwift
import IceCream
import CommonCrypto

final class StorageService {

    public let realm: Realm?
    public static let shared = StorageService()
    
    init(inMemory: Bool = false) {
        let configuration: Realm.Configuration
        if inMemory || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            configuration = Realm.Configuration( inMemoryIdentifier: "inMemory" )
        } else {
            configuration = Realm.Configuration()
        }
        self.realm = try? Realm(configuration: configuration)
    }
    
    func saveOrUpdateObject(object: Object) throws {
        guard let storage = realm else { return }
        storage.writeAsync {
            storage.add(object, update: .all)
        }
    }
    
    func saveOrUpdateAllObjects(objects: [Object]) throws {
        try objects.forEach {
            try saveOrUpdateObject(object: $0)
        }
    }
    
    func deleteObject(object: Object) throws {
        guard let storage = realm else { return }
        try storage.write {
            if var obj = object as? CKSafeDelete {
                obj.isDeleted = true
            } else {
                storage.delete(object)
            }
        }
    }
    
    func deleteObjectWithId<T: Object>(type: T.Type, id: String) throws {
        guard let storage = realm else { return }
        try storage.write {
            guard let object = storage.object(ofType: T.self, forPrimaryKey: id) else { return }
            if var object = object as? CKSafeDelete {
                object.isDeleted = true
            } else {
                storage.delete(object)
            }
        }
    }
    
    func fetch<T: Object>(by type: T.Type) -> [T] {
        guard let storage = realm else { return [] }
        return storage.objects(T.self).toArray()
    }
    
}

extension Results {
    func toArray() -> [Element] {
        .init(self)
    }
}
