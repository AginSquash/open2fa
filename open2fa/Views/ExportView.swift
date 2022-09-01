//
//  ExportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportResult: Identifiable {
    let id = UUID()
    var title: String
    var message: String
}

struct ExportView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    static let fileName = "encrypted.o2fa"
    static var baseURL: URL {
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
        return url.appendingPathComponent(ExportView.fileName)
    }
    
    @State private var passwordEntered = String()
    @State private var exportResult: ExportResult? = nil
    @State private var showExportView = false
    @State private var encryptedFile: O2FADocument = O2FADocument(url: baseURL)
    
    var body: some View {
        return Form {
            Section {
                VStack(alignment: .leading, spacing: 15) {
                    Text("For your protection, we need to identify you. Please enter your password below.")
                    Text("🔐 All your codes will remain encrypted with AES-256")
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
        .alert(item: $exportResult) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("Ok"), action: { if error.title == NSLocalizedString("Success", comment: "Success") { self.presentationMode.wrappedValue.dismiss() } }) )
        }
        .fileExporter(
            isPresented: $showExportView,
            document: encryptedFile,
            contentType: UTType(filenameExtension: "o2fa")!,
            defaultFilename: "encrypted" ) { result in
            if case .success = result {
                    exportResult = ExportResult(title: NSLocalizedString("Success", comment: "Success"), message: NSLocalizedString("Your file successfully exported!", comment: "success exported"))
                    return
                  } else {
                    print("Oops: \(result)")
                  }
        }
    }

    
    func exportButton() {
        guard Core2FA_ViewModel.isPasswordCorrect(fileURL: ExportView.baseURL, password: passwordEntered) else {
            passwordEntered = String()
            exportResult = ExportResult(title: "Error", message: "You entered wrong password")
            return
        }
        passwordEntered = String()
        self.showExportView = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showExportView = true
        }
    }
    
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

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
