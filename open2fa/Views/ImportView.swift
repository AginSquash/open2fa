//
//  ImportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
import core_open2fa

struct IVResult: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var isSuccessful: Bool
}

struct ImportView: View {
    //@Environment(\.importFiles) var importAction
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("isFirstRun") var storageFirstRun: String = ""
    @AppStorage("isEnableLocalKeyChain") var storageLocalKeyChain: String = ""
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }

    @State private var result: IVResult? = nil
    @State private var isEnableLocalKeyChain: Bool = true
    @State private var enteredPassword = String()
    @State private var showImportAction = false
    
    var body: some View {
            Form {
                Section {
                    Text("If you have already used Open2FA, please enter your password and select the file using button below.")
                }
                Section {
                    SecureField("Password", text: $enteredPassword)
                    VStack {
                        Toggle("🔐 Enable local keychain", isOn: $isEnableLocalKeyChain.animation(.default))
                                
                        if isEnableLocalKeyChain == false {
                            Text("FaceID and TouchID will be not available")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section {
                    Button(action: {
                        self.showImportAction = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.showImportAction = true
                        }
                    }, label: {
                        Text("Import")
                    })
                    .disabled(enteredPassword.isEmpty)
                }
                .navigationBarTitle("Import", displayMode: .inline)
                .alert(item: $result) { result in
                    Alert(title: Text(result.title), message: Text(result.message), dismissButton: .default(Text("Ok"), action: {
                        if result.isSuccessful {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }) )
                }
            }
            .fileImporter(
                isPresented: $showImportAction,
                allowedContentTypes: [UTType(filenameExtension: "o2fa")!],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let url: URL = try result.get().first else { return }
                    if url.startAccessingSecurityScopedResource() {
                        if (FileManager.default.secureCopyItem(at: url.absoluteURL, to: baseURL.absoluteURL)) {
                            url.stopAccessingSecurityScopedResource()
                            
                            let checkResult = Core2FA_ViewModel.checkFileO2FA(fileURL: baseURL, password: enteredPassword)
                            handleCheckResult(checkResult)
                        }
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        self.result = IVResult(title: "Error", message: "Unhandled error", isSuccessful: false)
                    }
                } catch {
                    self.result = IVResult(title: "Error", message: error.localizedDescription, isSuccessful: false)
                }
            }
    }
    /*
    func ProccessImportAction() {
        let type = UTType(filenameExtension: "o2fa")!
        importAction(singleOfType: [type], completion: { (result: Result<URL, Error>?) in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    if (FileManager.default.secureCopyItem(at: url.absoluteURL, to: baseURL.absoluteURL)) {
                        url.stopAccessingSecurityScopedResource()
                        
                        let checkResult = Core2FA_ViewModel.checkFileO2FA(fileURL: baseURL, password: enteredPassword)
                        handleCheckResult(checkResult)
                    }
                    url.stopAccessingSecurityScopedResource()
                } else {
                    self.result = IVResult(title: "Error", message: "Unhandled error", isSuccessful: false)
                }
            case .failure(let error):
                print("DEBUG: \(error.localizedDescription)")
                self.result = IVResult(title: "Error", message: error.localizedDescription, isSuccessful: false)
            case .none:
                return
            }
            return
        })
    } */
    
    func handleCheckResult(_ checkResult: FUNC_RESULT) {
        var title = "Error"
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
            title = "Imported!"
            message =  "Your o2fa file was imported successfully!"
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
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
            ImportView()
        
    }
}
