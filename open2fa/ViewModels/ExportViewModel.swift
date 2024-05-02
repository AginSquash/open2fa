//
//  ExportViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 02.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

class ExportViewModel: ObservableObject {
    let storage = StorageService.shared
    
    @Published var passwordEntered = String()
    @Published var isSecureExport = true
    @Published var exportResult: ExportResult? = nil
    @Published var showExportView = false
    @Published var show_UNSECURE_ExportView = false
    @Published var encryptedFile: O2FADocument? = nil
    @Published var unEncryptedFile: O2FA_Unencrypted? = nil
    
    func exportButtonAction() {
        guard Core2FA_ViewModel.isPasswordValid(password: passwordEntered) else { showError(.DecryptError); return }
        guard let salt = KeychainService.shared.getSalt() else { showError(.noSalt); return }
        guard let iv = KeychainService.shared.getIV() else { showError(.noIV); return }
        guard let kvc = KeychainService.shared.getKVC() else { showError(.noKVC); return }
        
        let publicED = PublicEncryptData(salt: salt, iv: iv, kvc: kvc)
        let fetchedAccountsObj = storage.fetch(by: AccountObject.self)
        
        let key = CryptoService.generateKey(pass: passwordEntered, salt: salt)
        let cryptoModule = CryptoService(key: key, IV: iv)
        let accountsData = fetchedAccountsObj.compactMap({ AccountData($0, cm: cryptoModule) })
        guard let encodedAccounts = try? JSONEncoder().encode(accountsData) else { showError(.cannotEncode); return }
        let encrypted = cryptoModule.encryptData(encodedAccounts)
        
        let accounts = AccountsFileStruct(publicEncryptData: publicED, accounts: encrypted)
        self.encryptedFile = O2FADocument(accountsFileStruct: accounts)
        self.showExportView = true
    }
    
    func showError(_ type: AlertType) {
        self.exportResult = ExportResult(title: "Error", message: type.rawValue)
    }
    
    func exportHandler(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let success):
            _debugPrint(success.absoluteURL)
        case .failure(let error):
            self.exportResult = ExportResult(title: "Error", message: error.localizedDescription )
        }
    }
}

extension ExportViewModel {
    struct ExportResult: Identifiable {
        let id = UUID()
        var title: String
        var message: String
    }
    
    enum AlertType: String {
        case DecryptError = "Wrong password"
        case noSalt = "Cannot find Salt"
        case noIV = "Cannot find IV"
        case noKVC = "Cannot find KVC"
        case cannotEncode = "Cannot encode Accounts"
    }
}
