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
    @Published var codes: [code]
    @Published var timeRemaning: Int = 0
    
    var core: CORE_OPEN2FA
    var timer: Timer?
    static var needUpdate = false
    
    
    @objc func updateTime() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "ss"
        let time = Int(df.string(from: date))!
        
        if Core2FA_ViewModel.needUpdate {
            self.codes = core.getListOTP()
            Core2FA_ViewModel.needUpdate = false
        }
        
        //Need test! 
        if (time == 0 || time == 30) {
            self.codes = core.getListOTP()
        }
        if time > 30 {
            timeRemaning = 30 - (time - 30)
        } else {
            timeRemaning = 30 - time
        }
        
    }
    
    init(fileURL: URL, pass: String) {
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = core.getListOTP()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
}
