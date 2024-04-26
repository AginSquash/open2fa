//
//  LAContext+Extension.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import LocalAuthentication

@available(iOS 15.0, macOS 12.0, *)
extension LAContext {
    
    func evaluatePolicy(_ policy: LAPolicy, localizedReason reason: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { cont in
            LAContext().evaluatePolicy(policy, localizedReason: reason) { result, error in
                if let error = error { return cont.resume(throwing: error) }
                cont.resume(returning: result)
            }
        }
    }
}
