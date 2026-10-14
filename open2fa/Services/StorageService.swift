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

struct AccountBlobUpdate {
    let id: String
    let iv: Data
    let accountData: Data
    let cipherVersion: Int
}

enum RealmBootstrap {
    static func migrate(_ migration: Migration, _ oldSchemaVersion: UInt64) {
        if oldSchemaVersion < 1 {
            migration.enumerateObjects(ofType: AccountObject.className()) { _, newObject in
                newObject?["cipherVersion"] = 1
            }
        }
    }

    static func configuration(inMemory: Bool) -> Realm.Configuration {
        let memory = inMemory || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if memory {
            return Realm.Configuration(
                inMemoryIdentifier: "inMemory",
                schemaVersion: 1,
                migrationBlock: migrate
            )
        }
        return Realm.Configuration(schemaVersion: 1, migrationBlock: migrate)
    }

    static func installDefault() {
        Realm.Configuration.defaultConfiguration = configuration(inMemory: false)
    }
}

struct MigrationWrapDTO {
    let salt: String
    let ivKVC: Data
    let kvc: Data
    let paramsJSON: Data
    let wrappedKey: Data
    let wrapIV: Data
    let wrapCipherVersion: Int
}

@MainActor
final class StorageService {

    public let realm: Realm?
    public static let shared = StorageService()

    init(inMemory: Bool = false) {
        RealmBootstrap.installDefault()
        let configuration = inMemory ? RealmBootstrap.configuration(inMemory: true) : Realm.Configuration.defaultConfiguration
        self.realm = try? Realm(configuration: configuration)
    }

    func saveOrUpdateObject(object: Object) throws {
        guard let storage = realm else { return }
        storage.writeAsync {
            storage.add(object, update: .all)
        }
    }

    func saveOrUpdateAllObjects(objects: [Object]) throws {
        guard let storage = realm else { return }
        try storage.write {
            storage.add(objects, update: .all)
        }
    }

    func deleteObject(object: Object) throws {
        guard let storage = realm else { return }
        try storage.write {
            Self.markDeleted(object)
        }
    }

    func deleteObjectWithId<T: Object>(type: T.Type, id: String) throws {
        guard let storage = realm else { return }
        try storage.write {
            guard let object = storage.object(ofType: T.self, forPrimaryKey: id) else { return }
            Self.markDeleted(object)
        }
    }

    func fetch<T: Object>(by type: T.Type) -> [T] {
        guard let storage = realm else { return [] }
        return storage.objects(T.self).toArray()
    }

    func hasLiveCiphertext() -> Bool {
        guard let storage = realm else { return false }
        return storage.objects(AccountObject.self).contains { object in
            !object.isDeleted && object.account_data?.isEmpty == false
        }
    }

    func account(id: String) -> AccountObject? {
        realm?.object(ofType: AccountObject.self, forPrimaryKey: id)
    }

    func commitReencryption(updates: [AccountBlobUpdate], wrap: VaultMigrationWrap) throws {
        guard let storage = realm else { throw VaultUnlockError.cryptoFailure }
        try storage.write {
            for update in updates {
                guard let object = storage.object(ofType: AccountObject.self, forPrimaryKey: update.id) else { continue }
                object.iv = update.iv
                object.account_data = update.accountData
                object.cipherVersion = update.cipherVersion
            }
            let deleted = storage.objects(AccountObject.self).filter("isDeleted == true")
            for object in deleted {
                object.account_data = Data()
                object.iv = Data()
            }
            storage.add(wrap, update: .modified)
        }
    }

    func migrationWrap() -> MigrationWrapDTO? {
        guard let wrap = realm?.object(ofType: VaultMigrationWrap.self, forPrimaryKey: VaultMigrationWrap.singletonID) else {
            return nil
        }
        return MigrationWrapDTO(
            salt: wrap.salt,
            ivKVC: wrap.ivKVC,
            kvc: wrap.kvc,
            paramsJSON: wrap.paramsJSON,
            wrappedKey: wrap.wrappedKey,
            wrapIV: wrap.wrapIV,
            wrapCipherVersion: wrap.wrapCipherVersion
        )
    }

    func clearMigrationWrap() throws {
        guard let storage = realm else { return }
        try storage.write {
            if let wrap = storage.object(ofType: VaultMigrationWrap.self, forPrimaryKey: VaultMigrationWrap.singletonID) {
                storage.delete(wrap)
            }
        }
    }

    private static func markDeleted(_ object: Object) {
        if let account = object as? AccountObject {
            account.account_data = Data()
            account.iv = Data()
            account.isDeleted = true
            return
        }
        if var deletable = object as? CKSafeDelete {
            deletable.isDeleted = true
        } else {
            object.realm?.delete(object)
        }
    }
}

extension Results {
    func toArray() -> [Element] {
        .init(self)
    }
}
