//
//  CryptoHandler.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 22.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CryptoSwift

class CryptoService {
    private let key: [UInt8]
    
    static func generateKey(pass: String, salt: String) -> [UInt8] {
        let pass: [UInt8] = Array(pass.utf8)
        let salt: [UInt8] = Array(salt.utf8)
        
        let key: [UInt8] = try! PKCS5.PBKDF2(
            password: pass,
            salt: salt,
            iterations: 4096,
            keyLength: 32,
            variant: .sha2(.sha256)
        ).calculate()
        
        return key
    }
    
    static func generateIV() -> [UInt8] {
        return AES.randomIV(AES.blockSize)
    }
    
    static func generateSalt() -> String {
        let len = 16
        let pswdChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        let iv = String((0..<len).compactMap{ _ in pswdChars.randomElement() })
        return iv
    }
    
    init(key: [UInt8]) {
        self.key = key
    }
    
    func encryptData(iv: [UInt8], inputData: Data) -> Data? {
        let gcm = GCM(iv: iv, mode: .combined)
        guard let aes = try? AES(key: self.key, blockMode: gcm, padding: .noPadding) else { return nil }
        guard let encryptedBytes = try? aes.encrypt([UInt8](inputData)) else { return nil }
        return Data(encryptedBytes)
    }
    
    func decryptData(iv: [UInt8], inputData: Data) -> Data? {
        let gcm = GCM(iv: iv, mode: .combined)
        guard let aes = try? AES(key: self.key, blockMode: gcm, padding: .noPadding) else { return nil }
        guard let decryptedBytes = try? aes.decrypt(inputData.bytes) else { return nil } // pasword error?
        return Data(decryptedBytes)
    }
}
