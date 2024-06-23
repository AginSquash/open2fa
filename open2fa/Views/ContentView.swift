//
//  ContentView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 16.05.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var core_driver: Core2FA_ViewModel
    
    @State private var showSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                let timeLeftView = TimeLeftView(progress: core_driver.progress)
#if os(iOS) 
                List(core_driver.codes) { c in
                    HStack {
                        timeLeftView
                            .frame(width: 30, height: 30, alignment: .center)
                        CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning)
                        .padding(.leading, 5)
                    }
                    .animation(.default)
                    .transition(.opacity)
                }
                .navigationBarTitle("Open2FA")
                .navigationBarItems(
                    leading:
                        NavigationLink(destination: PreferencesView().environmentObject(self.core_driver), label: { Text("Preferences") }),
                    trailing:
                        NavigationLink(destination: AddCodeView().environmentObject(self.core_driver), label: { Text("Add") }) )
#else
                VStack {
                    List {
                        Section {
                            ForEach(core_driver.codes) { c in
                                HStack {
                                    timeLeftView
                                        .frame(width: 30, height: 30, alignment: .center)
                                    CodePreview(code: c, timeRemaning: self.core_driver.timeRemaning)
                                        .padding(.leading, 5)
                                }
                            }
                        } header: {
                            Spacer(minLength: 10).listRowInsets(EdgeInsets())
                        }
                        .animation(.default)
                        .transition(.opacity)
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.defaultMinListHeaderHeight, 0)
                }
                .navigationBarTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationBarItems(
                    leading:
                        NavigationLink(destination: PreferencesView().environmentObject(self.core_driver), label: { Text("Preferences") }),
                    trailing:
                        NavigationLink(destination: AddCodeView().environmentObject(self.core_driver), label: { Text("Add") }) )
#endif
                
                if core_driver.codes.count == 0 {
                    Text("Add your accounts using the button above")
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
            }
            .onAppear(perform: core_driver.syncTimer)
            onReceive(core_driver.viewDismissalModePublisher) { shouldPop in
                if shouldPop {
                    self.presentationMode.wrappedValue.dismiss()
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
        let core_driver = Core2FA_ViewModel.TestModel
        
        return ContentView(core_driver: core_driver) //.environmentObject(core_driver)
    }
}
