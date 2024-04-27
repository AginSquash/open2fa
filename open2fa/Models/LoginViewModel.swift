//
//  LoginViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import LocalAuthentication
import SwiftUI

enum errorTypeEnum {
    case passwordIncorrect
    case thisFileNotExist
    case passwordDontMatch
    case keyNotSaved
}
struct errorType: Identifiable {
    let id = UUID()
    let error: errorTypeEnum
}

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
        
        guard let core = Core2FA_ViewModel(password: self.enteredPassword) else { self.errorDiscription = .init(error: .passwordIncorrect); return }
        self.core = core
        pushView()
    }
    
    func onAppear() {
        if isEnablelocalKeychain {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: biometricAuth)
        }
    }
    
    func tryBiometricAuth() {
        if isEnablelocalKeychain {
            biometricAuth()
        }
    }
    
    private func biometricAuth() {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
        let task = Task {
            guard let result = try? await context.evaluatePolicy(policy, localizedReason: reason) else { return }
            if result {
                guard let key = KeychainWrapper.shared.getKey() else { self.errorDiscription = .init(error: .keyNotSaved); return }
                guard let core = Core2FA_ViewModel(key: key) else { self.errorDiscription = .init(error: .passwordIncorrect); return }
                self.core = core
                self.pushView()
            }
        }
    }
    
    private func pushView() {
        withAnimation {
             self.isUnlocked = true
        }
    }
    
}
