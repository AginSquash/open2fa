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
    enum BAError: Error {
        case authError
        case noBiometric
        case keychainNotSet
    }
    
    static func tryBiometricAuth(_ completionHandler: @escaping (Result<Bool, BAError>)->() ) {
        guard UserDefaultsService.get(key: .storageLocalKeychainEnable) else { completionHandler(.failure(.keychainNotSet)); return }
        let context = LAContext()
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            completionHandler(.failure(.noBiometric))
            return
        }
        
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                DispatchQueue.main.async {
                    completionHandler(.success(true))
                }
            } catch let error {
                DispatchQueue.main.async {
                    completionHandler(.failure(.authError))
                }
            }
        }
    }
}
