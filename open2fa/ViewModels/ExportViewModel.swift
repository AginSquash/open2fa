//
//  ExportViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 02.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

@MainActor
class ExportViewModel: ObservableObject {
    let storage = StorageService.shared
    
    @Published var passwordEntered = String()
    @Published var isSecureExport = true
    @Published var exportResult: ExportResult? = nil
    @Published var showExportView = false
    @Published var show_UNSECURE_ExportView = false
    @Published var encryptedFile: O2FADocument? = nil
    @Published var unEncryptedFile: O2FA_Unencrypted? = nil
    
    private var exportedCount: Int = 0
    
    func exportButtonAction() {
        guard Core2FA_ViewModel.isPasswordValid(password: passwordEntered) else { showError(.DecryptError); return }
        guard let salt = KeychainService.shared.getSalt() else { showError(.noSalt); return }
        guard let iv_publicED = KeychainService.shared.getIV_KVC() else { showError(.noIV); return }
        guard let kvc = KeychainService.shared.getKVC() else { showError(.noKVC); return }
        
        let publicED = PublicEncryptData(salt: salt, iv_kvc: iv_publicED, kvc: kvc)
        let fetchedAccountsObj = storage.fetch(by: AccountObject.self)
        
        let key = CryptoService.generateKey(pass: passwordEntered, salt: salt)
        let cryptoModule = CryptoService(key: key)
        let accountsData = fetchedAccountsObj.compactMap({ AccountData($0, cm: cryptoModule) })
        self.exportedCount = accountsData.count
        guard let encodedAccounts = try? JSONEncoder().encode(accountsData) else { showError(.cannotEncode); return }
        let iv = CryptoService.generateIV()
        let encrypted = cryptoModule.encryptData(iv: iv, inputData: encodedAccounts)
        
        let accounts = AccountsFileStruct(publicEncryptData: publicED, iv: iv, accounts: encrypted)
        self.encryptedFile = O2FADocument(accountsFileStruct: accounts)
        self.showExportView = true
    }
    
    func showSuccessAlert() {
        self.exportResult = ExportResult(title: "Exported!", message: "Successfully exported \(exportedCount) accounts", isSuccessful: true)
    }
    
    func showError(_ type: AlertType) {
        self.exportResult = ExportResult(title: "Error", message: type.rawValue)
    }
    
    func exportHandler(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let success):
            _debugPrint(success.absoluteURL)
            passwordEntered = ""
            showSuccessAlert()
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
        var isSuccessful: Bool = false
    }
    
    enum AlertType: String {
        case DecryptError = "Wrong password"
        case noSalt = "Cannot find Salt"
        case noIV = "Cannot find IV"
        case noKVC = "Cannot find KVC"
        case cannotEncode = "Cannot encode Accounts"
    }
}
