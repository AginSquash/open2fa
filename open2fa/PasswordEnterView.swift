//
//  PasswordEnterView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import LocalAuthentication
 
struct PasswordEnterView: View {
    
    @State var isUnlocked = false
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file")
    @State private var pass = "pass"
    @State private var enteredPassword = ""
    
    var body: some View {
        NavigationView {
            
            VStack {
                Group {
                    Text("Please, enter your password:")
                    SecureField("Password", text: $enteredPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }.padding(.horizontal)
                
                NavigationLink(
                    destination:
                        ContentView().environmentObject(Core2FA_ViewModel(fileURL: self.url, pass: self.enteredPassword))
                            .navigationBarTitle("")
                            .navigationBarHidden(true),
                    isActive: self.$isUnlocked,
                    label: {
                        Text("Unlock").onTapGesture {
                            if self.enteredPassword == "pass" {
                                self.isUnlocked = true
                            }
                        }.padding(.top)
                })
            }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: auth)

    }
    
    func auth() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please authenticate to unlock your codes"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                
                DispatchQueue.main.async {
                    if success {
                        self.enteredPassword = "pass"
                        self.isUnlocked = true
                    }
                }
            }
        }
    }
}


struct PasswordEnterView_Previews: PreviewProvider {
    static var previews: some View {
        return PasswordEnterView()
    }
}
