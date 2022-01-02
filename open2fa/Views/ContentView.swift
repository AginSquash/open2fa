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
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    let timeLeftView = TimeLeftView(progress: core_driver.progress)
                    ForEach (core_driver.codes) { c in
                        HStack {
                            timeLeftView
                                .frame(width: 30, height: 30, alignment: .center)
                            CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning, progress: self.core_driver.progress )
                        }
                    }
                    .animation(.default)
                    .transition(.opacity)
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
#if os(iOS) && !targetEnvironment(macCatalyst)
        .blur(radius: core_driver.isActive ? 0 : 5)
#endif
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file")
        core_driver.DEBUG()
        
        return ContentView().environmentObject(core_driver)
    }
}
