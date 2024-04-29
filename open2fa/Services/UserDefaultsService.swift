//
//  UDefaultsService.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 27.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import Foundation

class UserDefaultsService {
    enum UserDefaultsTags: String {
        case storageLocalKeychainEnable
        case cloudSync
        case alreadyInited
    }
    
    static func set(_ value: Bool, forKey key: UserDefaultsTags) {
        UserDefaults.standard.set(value, forKey: key.rawValue )
    }
    
    static func get(key: UserDefaultsTags) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
}
