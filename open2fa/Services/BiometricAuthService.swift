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
    
    static func authenticatedContext() async throws -> LAContext {
        guard UserDefaultsService.get(key: .storageLocalKeychainEnable) else { throw BAError.keychainNotSet }
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 10
        let reason = NSLocalizedString("Please identify yourself to unlock the app", comment: "Biometric auth")

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            _debugPrint(error?.localizedDescription ?? "Can't evaluate policy")
            throw BAError.noBiometric
        }

        let isAuthenticated = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        guard isAuthenticated else { throw BAError.authError }
        return context
    }

    static func tryBiometricAuth() async throws -> Bool {
        _ = try await authenticatedContext()
        return true
    }
}
