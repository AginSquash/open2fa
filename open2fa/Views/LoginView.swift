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

struct EmptyView: View {
    var body: some View {
        Text("Some text")
    }
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
                    
                        VStack {
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
                                    Toggle("🔐 Enable FaceID / TouchID", isOn: $vm.isEnablelocalKeychain.animation(.default))
                                    
                                    if !vm.isEnablelocalKeychain {
                                        Text("FaceID and TouchID will be not available")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                }
                            }  else {
                                Text("Please, enter your password")
                                    .padding(.bottom, geo.size.height / 50 )
                                SecureField("Password", text: $vm.enteredPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
                                        Image(systemName: "faceid")
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
                                NavigationLink("Import", destination: ImportView())
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
                            ContentView()
                                .environmentObject(core)
                                .navigationBarTitle("")
                                .navigationBarHidden(true),
                        isActive: $vm.isUnlocked) {
                            EmptyView()
                        }
                    .hidden()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: vm.onAppear)
        .alert(item: $vm.errorDiscription, content: getAlert)

    }
    
    func getAlert(_ error: errorType) -> Alert {
        if error.error == .thisFileNotExist {
            return Alert(title: Text("Error"), message: Text("File not exists"), dismissButton: .default(Text("Retry"), action: { self.vm.enteredPassword = "" }))
        }
        
        if error.error == .passwordDontMatch {
            return Alert(title: Text("Error"), message: Text("Passwords don't match"), dismissButton: .default(Text("Retry"), action: { self.vm.enteredPassword = ""; self.vm.enteredPasswordSecond = "" }))
        }
        
        return Alert(title: Text("Error"), message: Text("Password is incorrect"), dismissButton: .default(Text("Retry"), action: { self.vm.enteredPassword = "" }))
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
