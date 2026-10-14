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
    @State var isEnableLocalKeyChain: Bool = UserDefaultsService.get(key: .storageLocalKeychainEnable)
    
    var serviceUUID: String
    
    @State private var enteredPassword: String = ""
    @State private var isUnlocked: Bool = false
    @State private var showPasswordError: Bool = false
    @State private var isCloseExport: Bool = false
    @State private var isChecking = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Please, enter your password")
                SecureField("Password", text: $enteredPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                NavigationLink(
                    destination:
                        ExportServiceView(serviceUUID: serviceUUID, isCloseExport: $isCloseExport)
                        .environmentObject(core_driver)
                        .navigationBarTitle("")
                        .navigationBarHidden(true),
                    isActive: $isUnlocked,
                               label: {
                    Button("Unlock", action: {
                        guard !isChecking else { return }
                        isChecking = true
                        let password = enteredPassword
                        Task {
                            let isValid = await core_driver.verifyPassword(password)
                            isChecking = false
                            if isValid {
                                isUnlocked = true
                            } else {
                                enteredPassword = ""
                                showPasswordError = true
                            }
                        }
                    })
                    .disabled(isChecking || enteredPassword.isEmpty)
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
                if isCloseExport {
                    self.presentationMode.wrappedValue.dismiss()
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: auth)
            })
            .alert(isPresented: $showPasswordError) {
                Alert(title: Text("Error"), message: Text("Password is incorrect"), dismissButton: .default(Text("Retry"), action: { self.enteredPassword = "" }))
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Close")
                    })
                }
            })
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    func auth() {
        Task {
            guard let isAuth = try? await BiometricAuthService.tryBiometricAuth() else {
                return _debugPrint("Error on Auth");
            }
            self.isUnlocked = isAuth
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel.TestModel

        let firstID = core_driver.codes.first!.id
        
        return AuthView(serviceUUID: firstID).environmentObject(core_driver)
    }
}
