//
//  PasswordEnterView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import LocalAuthentication

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
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("encrypted.o2fa") //test_file 
    @State private var enteredPassword = ""
    @State private var enteredPasswordCHECK = ""
    @State private var errorDiscription: errorType? = nil
    @State private var isFirstRun = false
    
    var body: some View {
        NavigationView {
            
            ZStack {
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
                    Spacer()
                }.padding(.top, 50)
                
                VStack{
                    Group {
                        if isFirstRun {
                            Text("For start using 2FA, create a password")
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .layoutPriority(1)
                            SecureField("Please create password", text: $enteredPassword)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                                 .padding(.top)
                            SecureField("Re-enter password", text: $enteredPasswordCHECK)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.bottom)
                        } else {
                            Text("Please, enter your password")
                            SecureField("Password", text: $enteredPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }.padding(.horizontal)
                    
                    NavigationLink(
                        destination:
                            ContentView().environmentObject(Core2FA_ViewModel(fileURL: self.url, pass: self.enteredPassword))
                                .navigationBarTitle("")
                                .navigationBarHidden(true),
                        isActive: self.$isUnlocked,
                        label: {
                            Button(action: {
                                if self.isFirstRun {
                                    
                                    guard self.enteredPassword == self.enteredPasswordCHECK else {
                                        self.errorDiscription = errorType(error: .passwordDontMatch)
                                        return
                                    }
                                    
                                    _ = Core2FA_ViewModel(fileURL: self.url, pass: self.enteredPassword)
                                    UserDefaults.standard.set(true, forKey: self.url.absoluteString)
                                    setPasswordKeychain(name: self.url.absoluteString, password: self.enteredPassword)
                                    self.isUnlocked = true
                                    return
                                }
                                
                                if Core2FA_ViewModel.isPasswordCorrect(fileURL: self.url, password: self.enteredPassword) {
                                    
                                    /// need add check for exist
                                    if getPasswordFromKeychain(name: self.url.absoluteString) == nil {
                                        setPasswordKeychain(name: self.url.absoluteString, password: self.enteredPassword)
                                    }
                                    
                                    self.isUnlocked = true
                                } else {
                                    self.errorDiscription = errorType(error: .passwordIncorrect)
                                }
                            }, label: {
                                Text( isFirstRun ? "Create" : "Unlock")
                            })
                        })
                        .disabled( (enteredPassword != enteredPasswordCHECK ) || ( enteredPassword.isEmpty ) )
                }
                .padding(.top, keyboard.currentHeight * 0.5) //yep we need to use 'top'. it's bug in SwiftUI?
                //.edgesIgnoringSafeArea(.bottom)
                //.animation(.easeOut(duration: 0.16))
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }
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
        if CheckIsFristRun() {
            self.isFirstRun = true
            return
        }
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please authenticate to unlock your codes"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                
                DispatchQueue.main.async {
                    if success {
                        if let pass = getPasswordFromKeychain(name: self.url.absoluteString) {
                            self.enteredPassword = pass
                            self.isUnlocked = true
                        } else {  }
                    }
                }
            }
        }
    }
    
    func CheckIsFristRun() -> Bool {
        if UserDefaults.standard.string(forKey: url.absoluteString) == nil {
            return true
        } else {
            return false
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
        return Group {
            PasswordEnterView()
            PasswordEnterView()
                .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
