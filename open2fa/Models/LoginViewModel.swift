//
//  LoginViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import LocalAuthentication

class LoginViewModel: ObservableObject {
    enum UserDefaultsTags: String {
        case storageLocalKeyChainEnable = "isEnableLocalKeyChain"
    }
    
    @Published var isUnlocked: Bool = false
    @Published var isEnablelocalKeychain: Bool
    @Published var enteredPassword: String = ""
    @Published var enteredPasswordSecond = ""
    @Published var errorDiscription: errorType? = nil
    
    @Published var core: Core2FA_ViewModel?
    
    let isFirstRun: Bool
    
    var isDisableLoginButton: Bool {
        return (enteredPassword != enteredPasswordSecond && isFirstRun) || ( enteredPassword.isEmpty )
    }
    
    init() {
        let defaults = UserDefaults.standard
        self.isEnablelocalKeychain = defaults.bool(forKey: UserDefaultsTags.storageLocalKeyChainEnable.rawValue)
        self.isFirstRun = Core2FA_ViewModel.isFirstRun()
    }
    
    func loginButtonAction() {
        
        if self.isFirstRun {
            let defaults = UserDefaults.standard
            //defaults.set(localKeychainEnable, forKey: UserDefaultsTags.storageLocalKeyChainEnable.rawValue)
            
            /*
            storageFirstRun = baseURL.absoluteString
            if isEnableLocalKeyChain {
                storageLocalKeyChain = "true"
                setPasswordKeychain(name: fileName, password: self.enteredPassword)
            } else {
                storageLocalKeyChain = "false"
            }
            */
        }
        
        
        tryBiometricAuth()
        
        guard let core = Core2FA_ViewModel(password: self.enteredPassword) else { return }
        self.core = core
        self.isUnlocked = true
    }
    
    func tryBiometricAuth() {
        if isEnablelocalKeychain {
            let context = LAContext()
            let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
            let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
            let task = Task {
                guard let result = try? await context.evaluatePolicy(policy, localizedReason: reason) else { return }
                if result {
                    guard let key = KeychainWrapper.shared.getKey() else { return }
                    guard let core = Core2FA_ViewModel(key: key) else { return }
                    self.core = core
                    self.isUnlocked = true
                }
            }
        }
    }
    
    private func biometricAuth2() {
        guard isFirstRun == false else {
            return
        }
        
        /*
        guard storageLocalKeyChain == "true" else {
            return
        }
        */
        let context = LAContext()
        var error: NSError?

        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                
                DispatchQueue.main.async {
                    if success {
                        if let key = KeychainWrapper.shared.getKey() {
                            
                        } else { return }
                        /*
                        if let pass = getPasswordFromKeychain(name: fileName) {
                            self.enteredPassword = pass
                            
                            self.core_driver.updateCore(fileURL: self.baseURL, pass: self.enteredPassword)
                            self.core_driver.loadCryptoModuleFromKeychain()
                            self.core_driver.setObservers()
                            
                            self.isUnlocked = true
                        } else { return }
                         */
                    }
                }
            }
        }
    }
}
