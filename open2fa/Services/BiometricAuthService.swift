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
    enum result {
        case successful
        case error
        case noBiometric
        case keychainNotSet
    }
    
    static func biometricAuth(_ handler: @escaping (result)->() ) {
        guard UserDefaultsService.get(key: .storageLocalKeychainEnable) else { handler(.keychainNotSet); return }
        let context = LAContext()
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            handler(.noBiometric)
            return
        }
        
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                DispatchQueue.main.async {
                    handler(.successful)
                }
            } catch let error {
                DispatchQueue.main.async {
                    handler(.error)
                }
            }
        }
    }
}
