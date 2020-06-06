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
    
    private var core: CORE_OPEN2FA
    private var timer: Timer?
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
    
    func deleteService(uuid: [UUID]) {
        for id in uuid {
            guard self.core.DeleteCode(id: id) == .SUCCEFULL else {
                fatalError("DeleteCode error")
            }
            //_ = core.getListOTP()
            codes.removeAll(where: { $0.id == id } )
        }
    }
    
    func DEBUG() {
        _ = core.AddCode(service_name: "Test1", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test2", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test3", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test4", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test5", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test6", code: "q4qghrcn2c42bgbz")
    }
    
    func addService(name: String, code: String) -> String? {
        let result = core.AddCode(service_name: name, code: code)
        if result == .SUCCEFULL {
            self.codes = self.core.getListOTP()
            return nil
        }
        
        switch result {
        case .ALREADY_EXIST:
            return "This name already taken"
        case .CODE_INCORRECT:
            return "This code is incorrect"
        default:
            return "Unknown error"
        }
    }
    
    init(fileURL: URL, pass: String) {
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = core.getListOTP()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
}
