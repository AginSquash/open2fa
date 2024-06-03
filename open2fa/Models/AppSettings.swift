//
//  AppSettings.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 03.06.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

class AppSettings {
    enum SettingsKeys: String {
        case lockTimeout
    }
    
    static let possibleLockTimeout: [Double] = [15.0, 30.0, 60.0, 120.0, 180.0]
    
    static func setDefaultsSettings() {
        UserDefaults.standard.set(60.0, forKey: SettingsKeys.lockTimeout.rawValue)
    }
    
    init() {
        if UserDefaults.standard.value(forKey: SettingsKeys.lockTimeout.rawValue) as? Double == nil {
            Self.setDefaultsSettings()
        }
    }
}
