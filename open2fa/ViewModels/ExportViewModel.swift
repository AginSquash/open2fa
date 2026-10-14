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
    @Published var exportResult: ExportResult? = nil
    @Published var showExportView = false
    @Published var encryptedFile: O2FADocument? = nil
    @Published var isExporting = false
    
    private var exportedCount: Int = 0
    
    func exportButtonAction() {
        guard !isExporting else { return }
        isExporting = true
        let password = passwordEntered
        Task {
            defer { isExporting = false }
            let params = KeychainService.shared.loadParams()
            guard KDFParams.isAllowed(params),
                  let saltString = KeychainService.shared.getSalt(),
                  let salt = CryptoService.saltData(stored: saltString, isBase64: params.saltIsBase64),
                  let ivKVC = KeychainService.shared.getIV_KVC(),
                  let kvc = KeychainService.shared.getKVC() else {
                showError(.noKVC)
                return
            }
            guard let key = try? await CryptoService.deriveKey(password: password, salt: salt, iterations: params.iterations) else {
                showError(.DecryptError)
                return
            }
            let cryptoModule = CryptoService(key: key)
            defer { cryptoModule.wipe() }
            guard cryptoModule.openKVC(iv: ivKVC, kvc: kvc, cipherVersion: params.cipherVersion) else {
                showError(.DecryptError)
                return
            }
            let fetchedAccountsObj = storage.fetch(by: AccountObject.self).filter { !$0.isDeleted }
            let accountsData = fetchedAccountsObj.compactMap { AccountData($0, cm: cryptoModule) }
            guard accountsData.count == fetchedAccountsObj.filter({ $0.account_data?.isEmpty == false }).count else {
                showError(.cannotEncode)
                return
            }
            self.exportedCount = accountsData.count
            guard let encodedAccounts = try? JSONEncoder().encode(accountsData),
                  let sealed = try? cryptoModule.encrypt(plaintext: encodedAccounts) else {
                showError(.cannotEncode)
                return
            }
            let publicED = PublicEncryptData(salt: saltString, iv_kvc: ivKVC, kvc: kvc, params: params)
            let accounts = AccountsFileStruct(
                publicEncryptData: publicED,
                iv: [UInt8](sealed.iv),
                accounts: sealed.ciphertext,
                accountsCipherVersion: KDFParams.current.cipherVersion
            )
            self.encryptedFile = O2FADocument(accountsFileStruct: accounts)
            self.showExportView = true
        }
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
