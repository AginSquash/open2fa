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
    struct AlertObject: Identifiable {
        let id = UUID()
        var title: String
        var message: String
        var isSuccessful: Bool = false
    }
    
    enum AlertType: String {
        case ReadFileError = "Unable to read file"
        case DecryptError = "Unable to decrypt file"
        case WrongFormat = "File is not in the correct format or is corrupted"
    }
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
    
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
                guard let codesFile = try? JSONDecoder().decode(CodesFile.self, from: data) else { showError(.WrongFormat); return }
                create(codesFile: codesFile)
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
    
    private func create(codesFile: CodesFile) {
        guard let coreAccounts = checkPassword(codesFile: codesFile) else { showError(.DecryptError); return }
        guard let core = Core2FA_ViewModel(password: enteredPassword, saveKey: isEnableLocalKeyChain) else { return }
        let accountsData = coreAccounts.compactMap(AccountData.init)
        core.importAccounts(accounts: accountsData)
        _debugPrint("Imported \(accountsData.count) accounts")
        UserDefaultsService.set(true, forKey: .alreadyInited)
        UserDefaultsService.set(isEnableLocalKeyChain, forKey: .storageLocalKeychainEnable)
        showSuccessAlert(importedAccountCount: accountsData.count)
    }
    
    private func checkPassword(codesFile: CodesFile) -> [CoreOpen2FA_AccountData]? {
        // if version ()
        guard let decrypted = decryptLegacyFile(codesFile: codesFile) else { return nil }
        guard let decoded = try? JSONDecoder().decode([CoreOpen2FA_AccountData].self, from: decrypted) else { return nil }
        return decoded
    }
    
    private func decryptLegacyFile(codesFile: CodesFile) -> Data? {
        guard let codes = codesFile.codes else { return nil }
        let key = enteredPassword.md5()
        do {
            let aes = try AES(key: key, iv: codesFile.IV) // aes256
            let textUint8 = try aes.decrypt( [UInt8](codes))
            return Data(hex: textUint8.toHexString())
        } catch { return nil }
    }
}
