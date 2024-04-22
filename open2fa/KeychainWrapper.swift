//
//  KeychainWrapper.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 26.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation

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

class KeychainWrapper {
    
    static public let sharedInstance = KeychainWrapper()
    
    public func setValue(name: KeychainTag, value: [UInt8]) {
        let data = Data(value)
        setValue(name: name, value: data)
    }
    
    public func setValue(name: KeychainTag, value: String) {
        guard let data = value.data(using: .utf8) else { fatalError("Cannot convert string to data on keychain") }
        setValue(name: name, value: data)
    }
    
    public func getValue(name: KeychainTag) -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: getService(for: name.rawValue),
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
            let data = existingItem[kSecValueData as String] as? Data,
            let account = existingItem[kSecAttrAccount as String] as? String
        else {
            fatalError("unexpectedPasswordData")
        }
        return data
    }
    
    public func getString(name: KeychainTag) -> String? {
        guard let data = getValue(name: name) else { return nil}
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    public func deleteValue(name: KeychainTag) {
        
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: name.rawValue,
                                    kSecAttrService as String: getService(for: name.rawValue)]
                                    
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { fatalError("ERROR: \(status)") }
    }
    
    private func getService(for name: String) -> String {
        "com.vladvrublevsky.open2fa.\(name)"
    }
    
    private func setValue(name: KeychainTag, value: Data) {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: name.rawValue,
                                    kSecAttrService as String: getService(for: name.rawValue),
                                    kSecValueData as String: value]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let attributes: [String: Any] = [kSecAttrAccount as String: name,
                                             kSecValueData as String: value]
            
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard status == errSecSuccess else { fatalError("ERROR \(status)") }
            _debugPrint("PASSWORD RENAMED with name \(name)")
            return
        }
        guard status == errSecSuccess else { fatalError("ERROR \(status)") }
        _debugPrint("PASSWORD SAVED with name \(name)")
    }
}
