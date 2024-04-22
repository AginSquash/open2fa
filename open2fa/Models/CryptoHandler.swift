//
//  CryptoHandler.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 22.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CryptoSwift

class CryptoModule {
    public static let sharedInstance = CryptoModule()
    
    private var key: [UInt8]
    private var IV: [UInt8]
    private let aes: AES
    
    func generateKey() {
        let pass: [UInt8] = Array("pass".utf8)
        let salt: [UInt8] = Array("salt".utf8)
        
        let key: [UInt8] = try! PKCS5.PBKDF2(
            password: pass,
            salt: salt,
            iterations: 4096,
            keyLength: 32,
            variant: .sha2(.sha256)
        ).calculate()
        self.key = key
    }
    
    func generateIV() {
        self.IV = AES.randomIV(AES.blockSize)
    }
    
    init() {
        let pass: [UInt8] = Array("pass".utf8)
        let salt: [UInt8] = Array("salt".utf8)
        
        let key: [UInt8] = try! PKCS5.PBKDF2(
            password: pass,
            salt: salt,
            iterations: 4096,
            keyLength: 32,
            variant: .sha2(.sha256)
        ).calculate()
        self.key = key
        
        self.IV = AES.randomIV(AES.blockSize)
        
        self.aes = try! AES(key: self.key, blockMode: CBC(iv: self.IV), padding: .pkcs7)
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

func generateIV() -> String {
    let len = 16
    let pswdChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    let iv = String((0..<len).compactMap{ _ in pswdChars.randomElement() })
    return iv
}

func CryptAES256(key: String, iv: String, data: Data) -> Data? {
    let key = key.md5()
    do {
        let aes = try AES(key: key, iv: iv)
        let ciphertext = try aes.encrypt([UInt8](data))
        return  Data(hex: ciphertext.toHexString())
    } catch { print(error.localizedDescription) }
    return nil
}

func DecryptAES256(key: String, iv: String, data: Data) -> Data? {
    let key = key.md5()
    do {
        let aes = try AES(key: key, iv: iv) // aes256
        let textUint8 = try aes.decrypt( [UInt8](data))
        return Data(hex: textUint8.toHexString())
    } catch { return nil }
}

func stringToBytes(_ string: String) -> [UInt8]? {
    let length = string.count
    if length & 1 != 0 {
        return nil
    }
    var bytes = [UInt8]()
    bytes.reserveCapacity(length/2)
    var index = string.startIndex
    for _ in 0..<length/2 {
        let nextIndex = string.index(index, offsetBy: 2)
        if let b = UInt8(string[index..<nextIndex], radix: 16) {
            bytes.append(b)
        } else {
            return nil
        }
        index = nextIndex
    }
    return bytes
}
