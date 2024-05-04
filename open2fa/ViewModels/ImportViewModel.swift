//
//  ImportViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 01.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import CryptoSwift

class ImportViewModel: ObservableObject {
    
    @Published var alertObject: AlertObject? = nil
    @Published var isEnableLocalKeyChain: Bool = true
    @Published var enteredPassword = String()
    @Published var showImportAction = false
 
    func fileImportHandler(_ result: Result<URL, any Error>) {
            switch result {
            case .success(let file):
                print(file.absoluteString)
                guard file.startAccessingSecurityScopedResource() else { showError(.ReadFileError); return }
                guard let data = try? Data(contentsOf: file.absoluteURL) else { showError(.ReadFileError); return }
                file.stopAccessingSecurityScopedResource()
                
                if let codesFile = try? JSONDecoder().decode(CodesFile_legacy.self, from: data) {
                    guard let decrypted = decryptLegacyFile(codesFile: codesFile, pass: enteredPassword) else { showError(.DecryptError); return }
                    let accounts = decrypted.compactMap(AccountData.init)
                    saveImportedData(accountsData: accounts)
                    return
                }
                
                if let accountsFile = try? JSONDecoder().decode(AccountsFileStruct.self, from: data) {
                    guard let decrypted = decryptFile(accountsFile: accountsFile, pass: enteredPassword) else { showError(.DecryptError); return }
                    let publicED = accountsFile.publicEncryptData
                    KeychainService.shared.setSalt(salt: publicED.salt)
                    KeychainService.shared.setKVC(kvc: publicED.kvc)
                    KeychainService.shared.setIV_KVC(iv: publicED.iv_kvc)
                    saveImportedData(accountsData: decrypted)
                    return
                }
                
                showError(.WrongFormat)
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
    
    private func saveImportedData(accountsData: [AccountData]) {
        guard let core = Core2FA_ViewModel(password: enteredPassword, saveKey: isEnableLocalKeyChain) else { return }
        core.importAccounts(accounts: accountsData)
        UserDefaultsService.set(true, forKey: .alreadyInited)
        UserDefaultsService.set(isEnableLocalKeyChain, forKey: .storageLocalKeychainEnable)
        showSuccessAlert(importedAccountCount: accountsData.count)
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
    
    private func decryptFile(accountsFile: AccountsFileStruct, pass: String) -> [AccountData]? {
        let salt = accountsFile.publicEncryptData.salt
        let key = CryptoService.generateKey(pass: pass, salt: salt)
        
        let cryptoModule = CryptoService(key: key)
        let iv = accountsFile.iv
        
        if let accountsEncrypted = accountsFile.accounts {
            guard let decrypted = cryptoModule.decryptData(iv: iv, inputData: accountsEncrypted) else { return nil }
            return try? JSONDecoder().decode([AccountData].self, from: decrypted)
        }
        
        let kvc = accountsFile.publicEncryptData.kvc
        let iv_kvc = accountsFile.publicEncryptData.iv_kvc
        guard let decrypted = cryptoModule.decryptData(iv: iv_kvc, inputData: kvc) else { return nil }
        guard let _ = try? JSONDecoder().decode(AccountData.self, from: decrypted) else { return nil }
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
