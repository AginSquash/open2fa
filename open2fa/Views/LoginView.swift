//
//  PasswordEnterView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import LocalAuthentication

func _debugPrint(_ obj: Any) {
    print("DEBUG: \(obj)")
}

struct LoginView: View {
    @ObservedObject private var vm = LoginViewModel()
        
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack {
                        VStack(alignment: .trailing, spacing: 0) {
                             HStack {
                                 Image("LogoIcon")
                                     .resizable()
                                     .frame(width: 60, height: 60)
                                     .clipShape(RoundedRectangle(cornerRadius: 10))
                                 VStack {
                                     Text("Open2FA")
                                     .font(.title)
                                     Text("by Vlad Vrublevsky")
                                         .foregroundColor(.secondary)
                                         .font(.footnote)
                                 }
                             }
                         }
                        .frame(height: geo.size.height / 10)
                        .padding(.top, geo.size.height / 20)
                        .padding(.bottom, 10)
                    
                        Group {
                            Spacer()
                            if vm.isFirstRun {
                                Text("For start using Open2FA, create a password")
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .layoutPriority(1)
                                    .padding(.top, 5)
                                    .padding(.bottom, geo.size.height / 50 )
                                SecureField("Please create password", text: $vm.enteredPassword)
                                     .textFieldStyle(RoundedBorderTextFieldStyle())
                                SecureField("Re-enter password", text: $vm.enteredPasswordSecond)
                                     .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                VStack {
                                    if !vm.availableBiometricAuth.isEmpty {
                                        Toggle("🔐 Enable \(vm.availableBiometricAuth)", isOn: $vm.isEnablelocalKeychain.animation(.default))
                                    }
                                    Toggle("☁️ Enable iCloud", isOn: $vm.isEnableCloudSync)
                                        .disabled(!vm.cloudSyncAvailable)
                                    
                                }
                            }  else {
                                Text("Please, enter your password")
                                    .padding(.bottom, geo.size.height / 50 )
                                SecureField("Password", text: $vm.enteredPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                           
                                if (vm.isLoadedFromCloud) && (!vm.availableBiometricAuth.isEmpty) {
                                    Toggle("🔐 Enable \(vm.availableBiometricAuth)", isOn: $vm.isEnablelocalKeychain.animation(.default))
                                }
                            }
                        }.padding(.horizontal)
                        
                    VStack {
                        Button(action: vm.loginButtonAction, label: {
                            VStack {
                                Text( vm.isFirstRun ? "Create" : "Unlock")
                                    .padding(.top, geo.size.height / 50 )
                            }
                        })
                        .disabled(vm.isDisableLoginButton)
                                                
                        if !vm.isFirstRun && vm.isEnablelocalKeychain {
                            VStack {
                                Text("- or -")
                                    .foregroundColor(.secondary)
                                    .padding()
                                Button(action: vm.tryBiometricAuth, label: {
                                    HStack {
                                        Text("Retry")
                                        Image(systemName: vm.availableBiometricAuthImg)
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                })
                                
                            }
                        }
                        Spacer()
                    }
                    
                    if vm.isFirstRun {
                            VStack {
                                Spacer(minLength: 5)
                                Text("Already used Open2fa?")
                                NavigationLink("Import", destination: ImportView( importedSuccessfully: vm.importHandler))
                                    .padding(.bottom, geo.size.height / 15)
                            }
                        } else {
                            Spacer()
                                .frame(height: geo.size.height / 10)
                                .padding(.bottom, geo.size.height / 20)
                        }
                    }
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                
                // Programmatically push to main view
                if let core = vm.core {
                    NavigationLink(
                        destination:
                            ContentView(core_driver: core)
                                //.environmentObject(core)
                                .navigationBarTitle("")
                                .navigationBarHidden(true),
                        isActive: $vm.isUnlocked) {
                            Text("Programmatically push view")
                        }
                    .hidden()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: vm.onAppear)
        .alert(item: $vm.errorDiscription, content: getErrorAlert)
        .sheet(isPresented: $vm.showCloudLoadedAlert, content: {
            CloudImportView(deleteAction: vm.deleteCloudData, restoreAction: vm.restoreCloudData, disableAction: vm.disableCloud)
        })
    }
    
    func getErrorAlert(_ error: LoginViewModel.errorType) -> Alert {
        let message: String
        let action: ()->()
        
        switch error.error {
        case .passwordDontMatch:
            message = "Passwords don't match"
            action = {
                self.vm.enteredPassword = ""
                self.vm.enteredPasswordSecond = ""
            }
        case .passwordIncorrect:
            message = "Password is incorrect"
            action = {
                self.vm.enteredPassword = ""
            }
        case .keyNotSaved:
            message = "Please enter your password for further login with Face ID"
            action = { }
        default:
            message = "Unexpected error"
            action = {
                self.vm.enteredPassword = ""
            }
        }
        
        return Alert(title: Text("Error"), 
                     message: Text(NSLocalizedString(message, comment: message)),
                     dismissButton: .default(Text("Retry"), action: action))
    }
    
    func getCloudAlert(_ publicED: PublicEncryptData) -> Alert {
        Alert(title: Text("iCloud data found"),
              message: Text("Restore data from iCloud and enable synchronization?"),
              primaryButton:
                .default(Text("Enable"), action: vm.restoreCloudData),
              secondaryButton: .cancel())
    }
    
}


struct PasswordEnterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .previewDevice("iPhone 11")
            LoginView()
                .previewDevice("iPhone 8")
        }
    }
}
