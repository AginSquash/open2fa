//
//  ExportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct passwordError: Identifiable {
    let id = UUID()
    var message: String
}

struct ExportView: View {
    
    @Environment(\.exportFiles) var exportAction
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
    var dstURL: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Export")
        do {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError
        {
            print("Unable to create directory \(error.debugDescription)")
        }
       return url.appendingPathComponent(fileName)
    }
    
    @State private var passwordEntered = String()
    @State private var error: passwordError? = nil
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 15) {
                    Text("For your protection, we need to identify you. Please enter your password below.")
                    Text("🔐 All your codes will remain encrypted with AES256")
                }
                SecureField("Password", text: $passwordEntered)
            }
            Button(action: exportButton, label: {
                Text("Yes, I understand that I still need to put this file in a safe place.")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            })
        }
        .navigationBarTitle("Export", displayMode: .inline)
        .alert(item: $error) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("Ok")))
        }
    }
    
    func exportButton() {
        
        guard Core2FA_ViewModel.isPasswordCorrect(fileURL: baseURL, password: passwordEntered) else {
            error = passwordError(message: "You entered wrong password")
            passwordEntered = String()
            return
        }
        
        if FileManager.default.secureCopyItem(at: baseURL, to: dstURL) {
            exportAction(moving: dstURL) { result in
                    switch result {
                    case .success( _):
                        return
                    case .failure(let error):
                        print("Oops: \(error.localizedDescription)")
                    case .none:
                        return
                    }
                }
        }
    }
}

extension FileManager {

    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
