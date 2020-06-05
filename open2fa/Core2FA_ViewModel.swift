//
//  Core2FA_ViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 05.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import core_open2fa

class Core2FA_ViewModel: ObservableObject
{
    @Published var core: CORE_OPEN2FA
    
    init(fileURL: URL, pass: String) {
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
    }
}
