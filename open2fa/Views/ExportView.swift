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
    }
    
    func isDismiss(_ input: Bool) {
        if input {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
