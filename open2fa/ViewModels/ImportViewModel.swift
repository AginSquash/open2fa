//
//  ImportViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 01.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CryptoSwift

@MainActor
class ImportViewModel: ObservableObject {
    
    @Published var alertObject: AlertObject? = nil
    @Published var isEnableLocalKeyChain: Bool = true
    @Published var enteredPassword = String()
    @Published var showImportAction = false
 
    func fileImportHandler(_ result: Result<URL, any Error>) {
            switch result {
            case .success(let file):
                guard file.startAccessingSecurityScopedResource() else { showError(.ReadFileError); return }
                defer { file.stopAccessingSecurityScopedResource() }
                guard let data = try? Data(contentsOf: file) else { showError(.ReadFileError); return }
                Task { await importData(data) }
            case .failure(let error):
                self.alertObject = AlertObject(title: "Error", message: error.localizedDescription)
            }
    }
    
    func showError(_ type: AlertType) {
        self.alertObject = AlertObject(title: "Error", message: type.rawValue)
    }
    
    func showSuccessAlert(importedAccountCount: Int) {
        self.alertObject = AlertObject(title: "Imported", message: "Successfully imported \(importedAccountCount) accounts", isSuccessful: true)
    }
    
    private func importData(_ data: Data) async {
        if let accountsFile = try? JSONDecoder().decode(AccountsFileStruct.self, from: data) {
            guard let decrypted = await decryptFile(accountsFile: accountsFile, pass: enteredPassword) else {
                showError(.DecryptError)
                return
            }
            await commitImport(decrypted, legacy: false)
            return
        }

        if let codesFile = try? JSONDecoder().decode(CodesFile_legacy.self, from: data) {
            guard let decrypted = decryptLegacyFile(codesFile: codesFile, pass: enteredPassword) else {
                showError(.DecryptError)
                return
            }
            await commitImport(decrypted.compactMap(AccountData.init), legacy: true)
            return
        }

        showError(.WrongFormat)
    }

    private func commitImport(_ accounts: [AccountData], legacy: Bool) async {
        if !UserDefaultsService.get(key: .alreadyInited) {
            KeychainService.shared.reset()
        }
        do {
            let core = try await Core2FA_ViewModel.unlock(
                password: enteredPassword,
                saveKey: isEnableLocalKeyChain,
                enforcePolicy: false
            )
            try core.importAccounts(accounts: accounts)
            UserDefaultsService.set(true, forKey: .alreadyInited)
            UserDefaultsService.set(isEnableLocalKeyChain, forKey: .storageLocalKeychainEnable)
            var message = "Successfully imported \(accounts.count) accounts"
            if legacy {
                message += "\n" + NSLocalizedString("This backup used obsolete MD5 encryption and was re-encrypted.", comment: "")
            }
            self.alertObject = AlertObject(title: "Imported", message: message, isSuccessful: true)
        } catch {
            showError(.DecryptError)
        }
    }
    
    private func decryptLegacyFile(codesFile: CodesFile_legacy, pass: String) -> [CoreOpen2FA_AccountData]? {
        guard let codes = codesFile.codes else { return nil }
        let key = pass.md5()
        do {
            let aes = try AES(key: key, iv: codesFile.IV) // aes256
            let textUint8 = try aes.decrypt( [UInt8](codes))
            let decrypted = Data(hex: textUint8.toHexString())
            return try? JSONDecoder().decode([CoreOpen2FA_AccountData].self, from: decrypted)
        } catch { return nil }
    }
    
    private func decryptFile(accountsFile: AccountsFileStruct, pass: String) async -> [AccountData]? {
        let publicData = accountsFile.publicEncryptData
        let params = publicData.kdfParams
        guard KDFParams.isAllowed(params),
              let salt = CryptoService.saltData(stored: publicData.salt, isBase64: params.saltIsBase64),
              let key = try? await CryptoService.deriveKey(password: pass, salt: salt, iterations: params.iterations) else {
            return nil
        }
        let cryptoModule = CryptoService(key: key)
        defer { cryptoModule.wipe() }

        if let accountsEncrypted = accountsFile.accounts {
            let cipher = accountsFile.accountsCipherVersion ?? params.cipherVersion
            guard let decrypted = cryptoModule.decrypt(iv: Data(accountsFile.iv), payload: accountsEncrypted, cipherVersion: cipher) else {
                return nil
            }
            return try? JSONDecoder().decode([AccountData].self, from: decrypted)
        }

        guard cryptoModule.openKVC(iv: publicData.iv_kvc, kvc: publicData.kvc, cipherVersion: params.cipherVersion) else {
            return nil
        }
        return []
    }
}

// MARK: - Alerts
extension ImportViewModel {
    struct AlertObject: Identifiable {
        let id = UUID()
        var title: String
        var message: String
        var isSuccessful: Bool = false
    }
    enum AlertType: String {
        case ReadFileError = "Unable to read file"
        case DecryptError = "Wrong password"
        case WrongFormat = "File is not in the correct format or is corrupted"
    }
}
