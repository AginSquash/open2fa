//
//  ImportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel = ImportViewModel()
    var importedSuccessfully: (Bool)->()
    /*
    @AppStorage("isFirstRun") var storageFirstRun: String = ""
    @AppStorage("isEnableLocalKeyChain") var storageLocalKeyChain: String = ""
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
     */
    
    var body: some View {
            Form {
                Section {
                    Text("If you have already used Open2FA, please enter your password and select the file using button below.")
                }
                Section {
                    SecureField("Password", text: $viewModel.enteredPassword)
                    VStack {
                        Toggle("🔐 Enable FaceID / TouchID", isOn: $viewModel.isEnableLocalKeyChain.animation(.default))
                                
                        if viewModel.isEnableLocalKeyChain == false {
                            Text("FaceID and TouchID will be not available")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section {
                    Button(action: {
                        self.viewModel.showImportAction = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.viewModel.showImportAction = true
                        }
                    }, label: {
                        Text("Import")
                    })
                    .disabled(viewModel.enteredPassword.isEmpty)
                }
                .navigationBarTitle("Import", displayMode: .inline)
                .alert(item: $viewModel.alertObject) { result in
                    Alert(title: Text(result.title), message: Text(result.message), dismissButton: .default(Text("OK"), action: {
                        if result.isSuccessful {
                            self.importedSuccessfully(true)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }) )
                }
            }
            .fileImporter(isPresented: $viewModel.showImportAction, allowedContentTypes: [UTType(filenameExtension: "o2fa")!], onCompletion: viewModel.fileImportHandler)
    }
    
    /*
    func handleCheckResult(_ checkResult: FUNC_RESULT) {
        var title = NSLocalizedString("Error", comment: "Error")
        var message = String()
        switch checkResult {
        case .PASS_INCORRECT:
            message = "Entered password is incorrect"
            break
        case .FILE_NOT_EXIST:
            message = "FILE_NOT_EXIST"
            break
        case .CANNOT_DECODE:
            message = "File damaged"
            break
        case .FILE_UNVIABLE:
            message = "File damaged"
            break
        case .SUCCEFULL:
            title = NSLocalizedString("Imported!", comment: "Imported!")
            message =  NSLocalizedString("Your o2fa file was imported successfully!", comment: "successfully import")
            storageFirstRun = baseURL.absoluteString
            if isEnableLocalKeyChain {
                storageLocalKeyChain = "true"
                setPasswordKeychain(name: fileName, password: self.enteredPassword)
            } else {
                storageLocalKeyChain = "false"
            }
            break
        default:
            _debugPrint("no one")
        }
        if title == "Error" {
            try? FileManager.default.removeItem(atPath: baseURL.absoluteString)
        }
        self.result = IVResult(title: title, message: message, isSuccessful: title == "Error" ? false : true)
    }
     */
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView(importedSuccessfully: {_ in })
        
    }
}
