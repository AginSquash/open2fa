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
                        if Core2FA_ViewModel.isPasswordValid(password: self.enteredPassword) {
                            self.isUnlocked = true
                        } else {
                            self.enteredPassword = ""
                            self.showPasswordError = true
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
        BiometricAuthService.tryBiometricAuth { result in
            switch result {
            case .success(let success):
                self.isUnlocked = success
            case .failure(let failure):
                _debugPrint(failure.localizedDescription)
            }
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
