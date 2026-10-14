//
//  KeychainWrapper.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 26.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import KeychainAccess
import LocalAuthentication

@MainActor
class KeychainService {
    enum KTag: String {
        case key = "key"
        case salt = "salt"
        case iv_kvc = "iv_kvc"
        case kvc = "kvc"
        case cryptoParams = "cryptoParams"
    }

    private let keychainLocal: Keychain
    private let keychainBiometric: Keychain
    static public let shared = KeychainService()

    func getIV_KVC() -> [UInt8]? {
        guard let ivKC = try? keychainLocal.getData(KTag.iv_kvc.rawValue) else { return nil }
        return [UInt8](ivKC)
    }

    func setIV_KVC(iv: [UInt8]) {
        keychainLocal[data: KTag.iv_kvc.rawValue] = Data(iv)
    }

    func getSalt() -> String? {
        guard let saltKC = try? keychainLocal.getString(KTag.salt.rawValue) else { return nil }
        return saltKC
    }

    func setSalt(salt: String) {
        keychainLocal[KTag.salt.rawValue] = salt
    }

    func getKey(context: LAContext) -> Data? {
        let biometric = keychainBiometric.authenticationContext(context)
        if let data = try? biometric.getData(KTag.key.rawValue), !data.isEmpty {
            return data
        }
        guard let legacy = try? keychainLocal.getData(KTag.key.rawValue), !legacy.isEmpty else { return nil }
        try? setKey(legacy, context: context)
        return legacy
    }

    func setKey(_ key: Data, context: LAContext? = nil) throws {
        var writer = keychainBiometric
        if let context {
            writer = writer.authenticationContext(context)
        }
        try writer.set(key, key: KTag.key.rawValue)
        try? keychainLocal.remove(KTag.key.rawValue)
        UserDefaultsService.set(true, forKey: .biometricKeyStored)
    }

    func removeKey() {
        try? keychainLocal.remove(KTag.key.rawValue)
        try? keychainBiometric.remove(KTag.key.rawValue)
        UserDefaultsService.set(false, forKey: .biometricKeyStored)
    }

    func getKVC() -> Data? {
        return try? keychainLocal.getData(KTag.kvc.rawValue)
    }

    func setKVC(kvc: Data) {
        keychainLocal[data: KTag.kvc.rawValue] = kvc
    }

    func loadParams() -> KDFParams {
        guard let data = try? keychainLocal.getData(KTag.cryptoParams.rawValue),
              let params = try? JSONDecoder().decode(KDFParams.self, from: data),
              KDFParams.isAllowed(params) else {
            return .legacy
        }
        return params
    }

    func saveParams(_ params: KDFParams) {
        guard let data = try? JSONEncoder().encode(params) else { return }
        keychainLocal[data: KTag.cryptoParams.rawValue] = data
    }

    func apply(_ publicData: PublicEncryptData) {
        setSalt(salt: publicData.salt)
        setIV_KVC(iv: publicData.iv_kvc)
        setKVC(kvc: publicData.kvc)
        saveParams(publicData.kdfParams)
    }

    func reset() {
        try? keychainLocal.remove(KTag.iv_kvc.rawValue)
        try? keychainLocal.remove(KTag.kvc.rawValue)
        try? keychainLocal.remove(KTag.salt.rawValue)
        try? keychainLocal.remove(KTag.cryptoParams.rawValue)
        removeKey()
    }

    init() {
        self.keychainLocal = Keychain(service: "com.vladvrublevsky.open2fa.local")
            .synchronizable(false)
            .accessibility(.whenUnlockedThisDeviceOnly)
        self.keychainBiometric = Keychain(service: "com.vladvrublevsky.open2fa.biometric")
            .synchronizable(false)
            .accessibility(.whenUnlockedThisDeviceOnly, authenticationPolicy: .biometryCurrentSet)
    }
}
