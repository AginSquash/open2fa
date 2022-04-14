//
//  AuthView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 11.04.2022.
//  Copyright © 2022 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isEnableLocalKeyChain") var storageLocalKeyChain: String = ""
    let fileName = "encrypted.o2fa" // wow change this
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
    var isEnableLocalKeyChain: Bool {
        return storageLocalKeyChain == "true"
    }
    
    var serviceUUID: UUID
    
    @State private var enteredPassword: String = ""
    @State private var isUnlocked: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Please, enter your password")
                SecureField("Password:", text: $enteredPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                NavigationLink(
                    destination:
                        ExportServiceView(serviceUUID: serviceUUID)
                        .navigationBarTitle("")
                        .navigationBarHidden(true),
                    isActive: $isUnlocked,
                               label: {
                    Button("Unlock", action: {
                        if Core2FA_ViewModel.isPasswordCorrect(fileURL: self.baseURL, password: self.enteredPassword) {
                            _debugPrint(baseURL)
                            self.core_driver.isActive = true
                            self.isUnlocked = true
                        }
                    })
                })
                
                if isEnableLocalKeyChain {
                    VStack {
                        Text("- or -")
                            .foregroundColor(.secondary)
                            .padding()
                        Button(action: auth, label: {
                            HStack {
                                Text("Retry")
                                Image(systemName: "faceid")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        })
                        
                    }
                }
            }
            .padding()
            .navigationTitle("Authentication")
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: auth)
            })
        }
    }
    
    func auth() {
        guard isEnableLocalKeyChain else {
            return
        }
        
        let context = LAContext()
        var error: NSError? = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please authenticate to unlock your codes"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                
                DispatchQueue.main.async {
                    if success {
                        if let pass = getPasswordFromKeychain(name: fileName) {
                            self.enteredPassword = pass
                            
                            self.isUnlocked = true
                        }
                    }
                }
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(serviceUUID: UUID())
    }
}
