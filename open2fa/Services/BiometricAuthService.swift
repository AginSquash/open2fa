//
//  BiometricAuthService.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 04.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import LocalAuthentication

class BiometricAuthService {
    enum ResultBA {
        case successful
        case error
        case noBiometric
        case keychainNotSet
    }
    
    static func tryBiometricAuth(_ completionHandler: @escaping (ResultBA)->() ) {
        guard UserDefaultsService.get(key: .storageLocalKeychainEnable) else { completionHandler(.keychainNotSet); return }
        let context = LAContext()
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            completionHandler(.noBiometric)
            return
        }
        
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                DispatchQueue.main.async {
                    completionHandler(.successful)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completionHandler(.error)
                }
            }
        }
    }
}
