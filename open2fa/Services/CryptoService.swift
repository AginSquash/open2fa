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
    
    private let aes: AES
    
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
    
    init(key: [UInt8], IV: [UInt8]) {
        self.aes = try! AES(key: key, blockMode: CBC(iv: IV), padding: .pkcs7)
    }
    
    func encryptData(_ inputData: Data) -> Data? {
        guard let encryptedBytes = try? aes.encrypt(inputData.bytes) else { return nil }
        return Data(encryptedBytes)
    }
    
    func decryptData(_ inputData: Data) -> Data? {
        guard let decryptedBytes = try? aes.decrypt(inputData.bytes) else { return nil } // pasword error?
        return Data(decryptedBytes)
    }
}
