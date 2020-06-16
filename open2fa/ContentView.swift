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
    
    @State private var showSheet = false
    @State private var isActive = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach (core_driver.codes) { c in
                     CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning)
                }
            }
            .navigationBarTitle("Open 2FA")
            .navigationBarItems(leading:
                NavigationLink(destination: PreferencesView(), label: { Text("Preferences") }),
                                trailing:
                                    Button(action: { self.showSheet = true }, label: { Text("Add") }) )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showSheet) {
            AddCodeView().environmentObject(self.core_driver)
        }
    
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.DEBUG()
        
        return ContentView().environmentObject(core_driver)
    }
}
