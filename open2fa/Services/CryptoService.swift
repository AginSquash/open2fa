//
//  CryptoHandler.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 22.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CryptoKit
import CryptoSwift
import CommonCrypto
import Security

enum CryptoError: Error {
    case derivationFailed
    case randomFailed
    case encryptFailed
}

enum VaultUnlockError: Error {
    case wrongPassword
    case needsRecovery
    case weakPassword(String)
    case incompleteVault
    case cryptoFailure
    case keyNotSaved
}

struct KDFParams: Codable, Equatable {
    var version: Int
    var iterations: Int
    var cipherVersion: Int
    var saltIsBase64: Bool

    static let legacy = KDFParams(version: 1, iterations: 4096, cipherVersion: 1, saltIsBase64: false)
    static let current = KDFParams(version: 2, iterations: 600_000, cipherVersion: 2, saltIsBase64: true)

    var needsUpgrade: Bool { self != .current }

    func isNewer(than other: KDFParams) -> Bool {
        if version != other.version { return version > other.version }
        return iterations > other.iterations
    }

    static func isAllowed(_ params: KDFParams) -> Bool {
        (params.iterations == legacy.iterations || params.iterations == current.iterations)
            && (params.cipherVersion == 1 || params.cipherVersion == 2)
            && (params.version == 1 || params.version == 2)
    }
}

enum PasswordPolicy {
    static func rejectionReason(_ password: String) -> String? {
        if password.count < 12 {
            return "Password must be at least 12 characters"
        }
        if Set(password).count < 4 {
            return "Password is too simple"
        }
        let banned: Set<String> = [
            "passwordpassword", "password1234", "123456789012", "qwertyuiopas",
            "qwerty123456", "open2faopen2fa", "iloveyou1234", "adminadmin12"
        ]
        if banned.contains(password.lowercased()) {
            return "Password is too common"
        }
        return nil
    }
}

final class CryptoService {
    private var key: Data

    init(key: Data) {
        self.key = key
    }

    func wipe() {
        guard !key.isEmpty else { return }
        key.resetBytes(in: 0..<key.count)
        key.removeAll()
    }

    static func randomBytes(_ count: Int) throws -> Data {
        var data = Data(count: count)
        let status = data.withUnsafeMutableBytes { buffer -> OSStatus in
            guard let address = buffer.baseAddress else { return errSecAllocate }
            return SecRandomCopyBytes(kSecRandomDefault, count, address)
        }
        guard status == errSecSuccess else { throw CryptoError.randomFailed }
        return data
    }

    static func generateSalt() throws -> String {
        try randomBytes(16).base64EncodedString()
    }

    static func saltData(stored: String, isBase64: Bool) -> Data? {
        if isBase64 {
            return Data(base64Encoded: stored)
        }
        guard !stored.isEmpty else { return nil }
        return Data(stored.utf8)
    }

    static func deriveKey(password: String, salt: Data, iterations: Int) async throws -> Data {
        let passwordBytes = Array(password.utf8)
        let saltBytes = [UInt8](salt)
        return try await Task.detached(priority: .userInitiated) {
            try deriveKeyBlocking(password: passwordBytes, salt: saltBytes, iterations: iterations)
        }.value
    }

    static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return false }
        var diff: UInt8 = 0
        for index in 0..<lhs.count {
            diff |= lhs[index] ^ rhs[index]
        }
        return diff == 0
    }

    func encrypt(plaintext: Data) throws -> (iv: Data, ciphertext: Data) {
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plaintext, using: SymmetricKey(data: key), nonce: nonce)
        return (Data(nonce), sealed.ciphertext + sealed.tag)
    }

    func decrypt(iv: Data, payload: Data, cipherVersion: Int) -> Data? {
        if cipherVersion >= KDFParams.current.cipherVersion {
            return decryptCryptoKit(iv: iv, payload: payload)
        }
        return decryptLegacy(iv: iv, payload: payload)
    }

    func openKVC(iv: [UInt8], kvc: Data, cipherVersion: Int) -> Bool {
        guard let decrypted = decrypt(iv: Data(iv), payload: kvc, cipherVersion: cipherVersion) else { return false }
        return (try? JSONDecoder().decode(AccountData.self, from: decrypted)) != nil
    }

    func sealKVC() throws -> (iv: Data, kvc: Data) {
        let dummy = AccountData(
            name: UUID().uuidString,
            issuer: UUID().uuidString,
            secret: try Self.randomBytes(32)
        )
        let encoded = try JSONEncoder().encode(dummy)
        let sealed = try encrypt(plaintext: encoded)
        return (sealed.iv, sealed.ciphertext)
    }

    private func decryptCryptoKit(iv: Data, payload: Data) -> Data? {
        guard payload.count > 16, iv.count == 12 else { return nil }
        let ciphertext = payload.prefix(payload.count - 16)
        let tag = payload.suffix(16)
        do {
            let nonce = try AES.GCM.Nonce(data: iv)
            let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(box, using: SymmetricKey(data: key))
        } catch {
            return nil
        }
    }

    private func decryptLegacy(iv: Data, payload: Data) -> Data? {
        guard key.count == 32, !iv.isEmpty else { return nil }
        do {
            let gcm = GCM(iv: [UInt8](iv), mode: .combined)
            let aes = try AES(key: [UInt8](key), blockMode: gcm, padding: .noPadding)
            let decrypted = try aes.decrypt([UInt8](payload))
            return Data(decrypted)
        } catch {
            return nil
        }
    }

    private static func deriveKeyBlocking(password: [UInt8], salt: [UInt8], iterations: Int) throws -> Data {
        guard !password.isEmpty, !salt.isEmpty, iterations > 0 else { throw CryptoError.derivationFailed }
        var derived = Data(count: 32)
        let status: CCStatus = derived.withUnsafeMutableBytes { derivedBuf in
            password.withUnsafeBytes { passBuf in
                salt.withUnsafeBytes { saltBuf in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passBuf.bindMemory(to: Int8.self).baseAddress,
                        password.count,
                        saltBuf.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBuf.bindMemory(to: UInt8.self).baseAddress,
                        32
                    )
                }
            }
        }
        guard status == CCStatus(kCCSuccess) else { throw CryptoError.derivationFailed }
        return derived
    }
}
