//
//  BiometricAuthService.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 04.05.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import LocalAuthentication

@MainActor
class BiometricAuthService {
    enum BAError: Error {
        case authError
        case noBiometric
        case keychainNotSet
    }
    
    static func tryBiometricAuth() async throws -> Bool  {
        guard UserDefaultsService.get(key: .storageLocalKeychainEnable) else { throw BAError.keychainNotSet }
        let context = LAContext()
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            throw BAError.noBiometric
        }
        
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
}
