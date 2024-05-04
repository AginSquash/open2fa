//
//  KeychainWrapper.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 26.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import KeychainAccess

class KeychainService {
    enum KTag: String {
        case key = "key"
        case salt = "salt"
        case iv_kvc = "iv_kvc"
        case kvc = "kvc"
    }
    
    private let keychainLocal: Keychain
    static public let shared = KeychainService()
    
    
    // IV
    func getIV_KVC() -> [UInt8]? {
        guard let ivKC = try? keychainLocal.getData(KTag.iv_kvc.rawValue) else { return nil }
        return [UInt8](ivKC)
    }
    
    func setIV_KVC(iv: [UInt8]) {
        keychainLocal[data: KTag.iv_kvc.rawValue] = Data(iv)
    }
    
    
    // Salt
    func getSalt() -> String? {
        guard let saltKC = try? keychainLocal.getString(KTag.salt.rawValue) else { return nil }
        return saltKC
    }
    
    func setSalt(salt: String) {
        keychainLocal[KTag.salt.rawValue] = salt
    }
    
    
    // Key
    func getKey() -> [UInt8]? {
        guard let keyKC = try? keychainLocal.getData(KTag.key.rawValue) else { return nil }
        return [UInt8](keyKC)
    }
    
    func setKey(key: [UInt8]) {
        keychainLocal[data: KTag.key.rawValue] = Data(key)
    }
    
    func removeKey() {
        keychainLocal[data: KTag.key.rawValue] = nil
    }
    
    // KVC
    func getKVC() -> Data? {
        return try? keychainLocal.getData(KTag.kvc.rawValue)
    }
    
    func setKVC(kvc: Data) {
        keychainLocal[data: KTag.kvc.rawValue] = kvc
    }
    
    
    // Reset on first launch TODO: Fix on first startup
    func reset() {
        keychainLocal[data: KTag.iv_kvc.rawValue] = nil
        keychainLocal[data: KTag.kvc.rawValue] = nil
        keychainLocal[KTag.salt.rawValue] = nil
        removeKey()
    }
    
    init() {
        let isEnableCloudSync = UserDefaultsService.get(key: .cloudSync)
        self.keychainLocal = Keychain(service: "com.vladvrublevsky.open2fa.local")
                                                                .synchronizable(false)
                                                                .accessibility(.whenUnlockedThisDeviceOnly)
    }

}
