//
//  ContentView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 16.05.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa

struct ContentView: View {
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach (core_driver.core.getListOTP()) { c in
                    CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning)
                }
                .onDelete(perform: delete)
            }
            .navigationBarTitle("Open 2FA")
            .navigationBarItems(leading: EditButton(),
                                trailing:
                                    Button(action: {  }, label: { Text("Add") })
                                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func delete(at offset: IndexSet) {
        //some
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.core.AddCode(service_name: "Test1", code: "q4qghrcn2c42bgbz")
        core_driver.core.AddCode(service_name: "Test2", code: "q4qghrcn2c42bgbz")
        core_driver.core.AddCode(service_name: "Test3", code: "q4qghrcn2c42bgbz")
        
        return ContentView().environmentObject(core_driver)
    }
}
