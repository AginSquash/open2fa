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

enum errorTypeEnum {
    case passwordIncorrect
    case thisFileNotExist
    case passwordDontMatch
}
struct errorType: Identifiable {
    let id = UUID()
    let error: errorTypeEnum
}

struct PasswordEnterView: View {
    
    @ObservedObject private var keyboard = KeyboardResponder()

    @State var isUnlocked = false
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
    
    @State private var core_driver = Core2FA_ViewModel()
    
    @AppStorage("isEnableLocalKeyChain") var storageLocalKeyChain: String = ""
    @AppStorage("isFirstRun") var storageFirstRun: String = ""
    private var isFirstRun: Bool {
        return storageFirstRun == ""
    }
    
    
    @State private var enteredPassword = ""
    @State private var enteredPasswordCHECK = ""
    @State private var errorDiscription: errorType? = nil
    @State private var isEnableLocalKeyChain: Bool = true
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack {
                        VStack(alignment: .trailing, spacing: 0) {
                             HStack {
                                 GetAppIcon()
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
                            
                            if isFirstRun {
                                Text("For start using 2FA, create a password")
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .layoutPriority(1)
                                    .padding(.top, 5)
                                    .padding(.bottom, geo.size.height / 50 )
                                SecureField("Please create password", text: $enteredPassword)
                                     .textFieldStyle(RoundedBorderTextFieldStyle())
                                SecureField("Re-enter password", text: $enteredPasswordCHECK)
                                     .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                VStack {
                                    Toggle("🔐 Enable local keychain", isOn: $isEnableLocalKeyChain.animation(.default))
                                    
                                    if isEnableLocalKeyChain == false {
                                        Text("FaceID and TouchID will be not available")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                }
                                
                            } else {
                                Text("Please, enter your password")
                                    .padding(.bottom, geo.size.height / 50 )
                                SecureField("Password", text: $enteredPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }.padding(.horizontal)
                        
                        NavigationLink(
                            destination:
                                ContentView().environmentObject(core_driver)
                                    .navigationBarTitle("")
                                    .navigationBarHidden(true),
                            isActive: self.$isUnlocked,
                            label: {
                                Button(action: {
                                    if self.isFirstRun {
                                        storageFirstRun = baseURL.absoluteString
                                        if isEnableLocalKeyChain {
                                            storageLocalKeyChain = "true"
                                            setPasswordKeychain(name: fileName, password: self.enteredPassword)
                                        } else {
                                            storageLocalKeyChain = "false"
                                        }
                                        
                                        self.core_driver.updateCore(fileURL: self.baseURL, pass: self.enteredPassword)
                                        _debugPrint(baseURL)
                                        self.isUnlocked = true
                                        return
                                    }
                                    
                                    if Core2FA_ViewModel.isPasswordCorrect(fileURL: self.baseURL, password: self.enteredPassword) {
                                        
                                        /// need add check for exist
                                        if storageLocalKeyChain == "true" {
                                            if getPasswordFromKeychain(name: fileName) != enteredPassword {
                                                setPasswordKeychain(name: fileName, password: self.enteredPassword)
                                            }
                                        }
                                        
                                        self.core_driver.updateCore(fileURL: self.baseURL, pass: self.enteredPassword)
                                        _debugPrint(baseURL)
                                        self.isUnlocked = true
                                    } else {
                                        self.errorDiscription = errorType(error: .passwordIncorrect)
                                    }
                                }, label: {
                                    VStack {
                                        Text( isFirstRun ? "Create" : "Unlock")
                                            .padding(.top, geo.size.height / 50 )
                                        Spacer()
                                    }
                                })
                            })
                            .disabled( (enteredPassword != enteredPasswordCHECK && isFirstRun) || ( enteredPassword.isEmpty ) )
                        
                        
                        if isFirstRun {
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
            }
    
        
            .padding(.bottom, keyboard.currentHeight * 0.1) 
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: auth)
        .alert(item: $errorDiscription) { error in
            if error.error == .thisFileNotExist {
                return Alert(title: Text("Error"), message: Text("File not exists"), dismissButton: .default(Text("Retry"), action: { self.enteredPassword = "" }))
            }
            
            if error.error == .passwordDontMatch {
                return Alert(title: Text("Error"), message: Text("Passwords don't match"), dismissButton: .default(Text("Retry"), action: { self.enteredPassword = ""; self.enteredPasswordCHECK = "" }))
            }
            
            return Alert(title: Text("Error"), message: Text("Password is incorrect"), dismissButton: .default(Text("Retry"), action: { self.enteredPassword = "" }))
        }

    }
    
    func auth() {
        guard isFirstRun == false else {
            return
        }
        
        guard storageLocalKeyChain == "true" else {
            return
        }
        
        let context = LAContext()
        var error: NSError?

        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please authenticate to unlock your codes"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                
                DispatchQueue.main.async {
                    if success {
                        if let pass = getPasswordFromKeychain(name: fileName) {
                            self.enteredPassword = pass
                            
                            self.core_driver.updateCore(fileURL: self.baseURL, pass: self.enteredPassword) 
                            self.isUnlocked = true
                        } else { return }
                    }
                }
            }
        }
    }
    
    func GetAppIcon() -> Image? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String:Any],
        let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String:Any],
        let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
        let lastIcon = iconFiles.last else { return nil }
        let uiIcon = UIImage(named: lastIcon)!
        return Image(uiImage: uiIcon)

    }
    
}


struct PasswordEnterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PasswordEnterView()
                .previewDevice("iPhone 11")
            PasswordEnterView()
                .previewDevice("iPhone 8")
        }
    }
}
