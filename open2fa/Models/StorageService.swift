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
    private let storage: Realm?
    
    init(inMemory: Bool = false) {
        let configuration: Realm.Configuration
        if inMemory {
            configuration = Realm.Configuration( inMemoryIdentifier: "inMemory" )
        } else {
            configuration = Realm.Configuration()
        }
        self.storage = try? Realm(configuration: configuration)
    }
    
    func saveOrUpdateObject(object: Object) throws {
        guard let storage = storage else { return }
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
        if let obj = object as? AccountObject {
            obj.isDeleted = true
        } else {
            guard let storage = storage else { return }
            try storage.write {
                storage.delete(object)
            }
        }
    }
    
    func fetch<T: Object>(by type: T.Type) -> [T] {
        guard let storage = storage else { return [] }
        return storage.objects(T.self).toArray()
    }
    
}

extension Results {
    func toArray() -> [Element] {
        .init(self)
    }
}

extension String {
    
    func sha512_v2() -> Data? {
        let stringData = data(using: String.Encoding.utf8)!
        var result = Data(count: Int (CC_SHA512_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes { resultBytes in
            stringData.withUnsafeBytes { stringBytes in
                CC_SHA512 (stringBytes, CC_LONG(stringData.count), resultBytes)
            }
        }
        return result
    }
}
