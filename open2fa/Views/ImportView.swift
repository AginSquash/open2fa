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
                    Alert(title: Text(result.title), 
                          message: Text(result.message),
                          dismissButton: .default(Text("OK"), action: {
                        if result.isSuccessful {
                            self.importedSuccessfully(true)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }) )
                }
            }
            .fileImporter(isPresented: $viewModel.showImportAction, allowedContentTypes: [UTType(filenameExtension: "o2fa")!], onCompletion: viewModel.fileImportHandler)
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView(importedSuccessfully: {_ in })
        
    }
}
