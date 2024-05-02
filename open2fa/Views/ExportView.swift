//
//  ExportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ExportViewModel()
    //@EnvironmentObject var core_driver: Core2FA_ViewModel
    
    var body: some View {
        return Form {
            Section {
                VStack(alignment: .leading, spacing: 15) {
                    Text("For your protection, we need to identify you. Please enter your password below.")
                }
                SecureField("Password", text: $viewModel.passwordEntered)
            }
            
            Section {
                Toggle(isOn: $viewModel.isSecureExport, label: {
                    Text("Encrypted export")
                })
                if !viewModel.isSecureExport {
                    Text("⚠️ Warning! Your file with account keys will be exported in json format WITHOUT encryption!")
                } else {
                    Text("🔐 All your codes will remain encrypted with AES-256")
                }
            }
            
            Button(action: viewModel.exportButtonAction, label: {
                HStack {
                    Spacer()
                    Text("Export")
                        .foregroundColor(.red)
                    Spacer()
                }
            })
        }
        .padding([.top], 1) //Fix for bug with form in center of screen, not on top
        .navigationBarTitle("Export", displayMode: .inline)
        .alert(item: $viewModel.exportResult) { alert in
            Alert(title: Text(alert.title), 
                  message: Text(alert.message),
                  dismissButton: 
                    .default(Text("OK"),
                             action: { isDismiss(alert.isSuccessful) })
            )
        }
        .fileExporter(
            isPresented: $viewModel.showExportView,
            document: viewModel.encryptedFile,
            contentType: UTType(filenameExtension: "o2fa")!,
            defaultFilename: "encrypted", 
            onCompletion: viewModel.exportHandler)
        /*
        .fileExporter(
            isPresented: $viewModel.show_UNSECURE_ExportView,
            document: viewModel.unEncryptedFile,
            contentType: UTType.json,
            defaultFilename: "open2fa_unencrypted",
            onCompletion: { result in
            if case .success = result {
                viewModel.exportResult = ExportResult(title: NSLocalizedString("Success", comment: "Success"), message: NSLocalizedString("Your file successfully exported!", comment: "success exported"))
                    return
                  } else {
                    print("Oops: \(result)")
                  } }) */
    }
    
    func isDismiss(_ input: Bool) {
        if input {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /*
    func exportButton() {
        guard Core2FA_ViewModel.isPasswordValid(password: passwordEntered) else {
            passwordEntered = String()
            exportResult = ExportResult(title: "Error", message: "You entered wrong password")
            return
        }
        passwordEntered = String()
        self.showExportView = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isSecureExport == false {
                self.unEncryptedFile = O2FA_Unencrypted(accounts: core_driver.NoCrypt_ExportALLService() )
                self.show_UNSECURE_ExportView = true
                return
            }
            self.showExportView = true
        }
    }
    */
    /// Code for  unsecure export
    /*
     @State private var encryptedExport: Bool = true
     @State private var showEncryptionOffAlert = false
     
     var body: some View {
         let exportEncryptionChoosen = Binding<Bool>(
             get: { encryptedExport },
             set: {
                 if $0 == false {
                     self.showEncryptionOffAlert = true
                 } else {
                     withAnimation {
                         encryptedExport = true
                     }
                 }
             }
         )
     ...
     
     Section {
         Toggle("Still encrypted", isOn: exportEncryptionChoosen)
         if exportEncryptionChoosen.wrappedValue == false {
             Text("Your codes will not be protected by encryption, which will allow you to import them into other applications.\nIs an unsafe option")
                 .foregroundColor(.secondary)
         }
             
     }
     
     .alert(isPresented: $showEncryptionOffAlert) {
         Alert(title: Text("Warning!"), message: Text("Are you sure? This option will remove encryption from the file, which will make your file vulnerable to hacker attacks"), primaryButton: .destructive(Text("Export unencrypted"), action: { withAnimation { self.encryptedExport = false } }), secondaryButton: .default(Text("Cancel")))
     }
     */
}
/*
extension FileManager {

    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            _debugPrint("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

}
*/
struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
