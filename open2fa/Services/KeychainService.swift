//
//  KeychainWrapper.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 26.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import KeychainAccess

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

func getPasswordFromKeychain(name: String) -> String? {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "open2fa_FILE_\(name)",
        kSecMatchLimit as String: kSecMatchLimitOne,
        kSecReturnAttributes as String: true,
        kSecReturnData as String: true]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status != errSecItemNotFound else {
        _debugPrint("No password with name \(name)")
        return nil
    }
    guard status == errSecSuccess else { fatalError("ERROR UNHANDLER") }
    
    guard let existingItem = item as? [String : Any],
        let passwordData = existingItem[kSecValueData as String] as? Data,
        let password = String(data: passwordData, encoding: String.Encoding.utf8),
        let account = existingItem[kSecAttrAccount as String] as? String
    else {
        fatalError("unexpectedPasswordData")
    }
    return password
}

func setPasswordKeychain(name: String, password: String) {
    let account = name
    let passwordData = password.data(using: String.Encoding.utf8)!
    var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: account,
                                kSecAttrService as String: "open2fa_FILE_\(name)",
                                kSecValueData as String: passwordData]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecDuplicateItem {
        let attributes: [String: Any] = [kSecAttrAccount as String: account,
                                         kSecValueData as String: passwordData]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else { fatalError("ERROR \(status)") }
        _debugPrint("PASSWORD RENAMED with name \(name)")
        return
    }
    guard status == errSecSuccess else { fatalError("ERROR \(status)") }
    _debugPrint("PASSWORD SAVED with name \(name)")
}

func deletePasswordKeychain(name: String) {
    
    var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: name,
                                kSecAttrService as String: "open2fa_FILE_\(name)"]
                                
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { fatalError("ERROR: \(status)") }
}


enum KeychainTag: String {
    case key = "key"
    case salt = "salt"
    case iv = "IV"
}

class KeychainService {
    private let keychainCloud: Keychain
    private let keychainLocal: Keychain
    
    static public let shared = KeychainService()
    
    
    // IV
    func getIV() -> [UInt8]? {
        guard let ivKC = try? keychainCloud.getData("iv") else { return nil }
        return [UInt8](ivKC)
    }
    
    func setIV(iv: [UInt8]) {
        keychainCloud[data: "iv"] = Data(iv)
    }
    
    
    // Salt
    func getSalt() -> String? {
        guard let saltKC = try? keychainCloud.getString("salt") else { return nil }
        return saltKC
    }
    
    func setSalt(salt: String) {
        keychainCloud["salt"] = salt
    }
    
    
    // Key
    func getKey() -> [UInt8]? {
        guard let keyKC = try? keychainLocal.getData("key") else { return nil }
        return [UInt8](keyKC)
    }
    
    func setKey(key: [UInt8]) {
        keychainLocal[data: "key"] = Data(key)
    }
    
    func removeKey() {
        keychainLocal[data: "key"] = nil
    }
    
    // KVC
    func getKVC() -> Data? {
        return try? keychainCloud.getData("kvc")
    }
    
    func setKVC(kvc: Data) {
        keychainCloud[data: "kvc"] = kvc
    }
    
    init() {
        self.keychainCloud = Keychain(service: "com.vladvrublevsky.open2fa.cloud").synchronizable(true)
        self.keychainLocal = Keychain(service: "com.vladvrublevsky.open2fa.local")
                                                                .synchronizable(false)
                                                                .accessibility(.whenUnlockedThisDeviceOnly)
    }

}
