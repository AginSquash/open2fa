//
//  ContentView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 16.05.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct ContentView: View {
   // @EnvironmentObject var core_driver: Core2FA_ViewModel
    @StateObject var core_driver: Core2FA_ViewModel
    @Environment(\.presentationMode) private var presentationMode
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
                            CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning)
                            .padding(.leading, 5)
                        }
                    }
                    .animation(.default)
                    .transition(.opacity)
                }
                .navigationBarTitle("Open 2FA")
                .navigationBarItems(
                    leading:
                        NavigationLink(destination: PreferencesView(core_driver: core_driver) , label: { Text("Preferences") }),
                    trailing:
                                        NavigationLink(destination: AddCodeView(core: core_driver), label: { Text("Add") }) )
                
                if core_driver.codes.count == 0 {
                    Text("Add your accounts using the button above")
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
            }
            .onAppear(perform: core_driver.syncTimer)
            .onReceive(core_driver.viewDismissalModePublisher) { shouldPop in
                if shouldPop {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .animation(.none)
        }
#if os(iOS) && !targetEnvironment(macCatalyst)
        .blur(radius: core_driver.isActive ? 0 : 5)
#endif
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel.TestModel
        
        return ContentView(core_driver: core_driver)
    }
}
