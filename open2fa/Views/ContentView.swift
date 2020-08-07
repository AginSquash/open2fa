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
    
    static public var isHide = false
    
    var body: some View {
        NavigationView {
            ZStack {
                
                NavigationLink(
                    destination: PasswordEnterView().environmentObject(core_driver)
                        .navigationBarBackButtonHidden(true),
                    isActive: core_driver.isLocked,
                    label: {
                        Text("")
                    })
                
                List {
                    if core_driver.isActive == true {
                        ForEach (core_driver.codes.sorted(by: { $0.date < $1.date }) ) { c in
                            CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning)
                        }
                    }
                }
                .navigationBarTitle("Open 2FA")
                .navigationBarItems(
                    leading:
                        NavigationLink(destination: PreferencesView().environmentObject(self.core_driver), label: { Text("Preferences") }),
                    trailing:
                        NavigationLink(destination: AddCodeView().environmentObject(self.core_driver), label: { Text("Add") }) )
                
                if core_driver.codes.count == 0 {
                    Text("Add your codes using the button above")
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onDisappear(perform: {
            print("DEBUG: ContentView disapper")
            ContentView.isHide = true
        })
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file")
        //core_driver.DEBUG()
        
        return ContentView().environmentObject(core_driver)
    }
}
