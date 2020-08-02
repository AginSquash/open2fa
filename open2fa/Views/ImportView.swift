//
//  ImportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct IVResult: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var isSuccessful: Bool
}

struct ImportView: View {
    @Environment(\.importFiles) var importAction
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("isFirstRun") var storageFirstRun: String = ""
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }

    @State private var result: IVResult? = nil
    @State private var isEnableLocalKeyChain: Bool = true
    @State private var enteredPassword = String()
    
    var body: some View {
       //GeometryReader { geo in
         //   ZStack {
                //Form { }
                VStack {
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
                            Button(action: ProccessImportAction, label: {
                                Text("Import")
                            })
                        }
                    }
                    //.offset(y: geo.size.height / 2 - 100)
                }
            //}
                .navigationBarTitle("Import", displayMode: .inline)
            .alert(item: $result) { result in
                Alert(title: Text(result.title), message: Text(result.message), dismissButton: .default(Text("Ok"), action: {
                    if result.isSuccessful {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }) )
            }
        //}
    }
    
    func ProccessImportAction() {
        let type = UTType(filenameExtension: "o2fa")!
        importAction(singleOfType: [type], completion: { (result: Result<URL, Error>?) in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    if (FileManager.default.secureCopyItem(at: url.absoluteURL, to: baseURL.absoluteURL)) {
                        storageFirstRun = baseURL.absoluteString
                        self.result = IVResult(title: "Imported!", message: "Your o2fa file was imported successfully!", isSuccessful: true)
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
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
            ImportView()
        
    }
}
