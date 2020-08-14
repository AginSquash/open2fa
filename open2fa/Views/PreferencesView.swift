//
//  PreferencesView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa

struct PreferencesView: View {
    
    @AppStorage("isEnableLocalKeyChain") var storageLocalKeyChain: String = ""
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    
    @State private var chosenForDelete: code? = nil
    @State private var biometricStatusChange: Bool = false
    @State private var isEnableLocalKeyChain = Binding<Bool>(get: { false }, set: { _ in})
    
    var body: some View {
            List {
                Section(header: Text("Settings")) {
                    NavigationLink(destination: ExportView(), label: { Text("Export") })
                    Toggle(isOn: isEnableLocalKeyChain) {
                        Text("FaceID or TouchID enable")
                    }
                    if biometricStatusChange {
                        Text("Please, restart app and enter password to appear change")
                    }
                }
                Section(header: Text("Delete")) {
                    ForEach (core_driver.codes.sorted(by: { $0.date < $1.date }) ) { c in
                        HStack {
                            Text(c.name)
                            Spacer()
                            Text("added " + self.getWrappedDate(date: c.date))
                                .foregroundColor(.secondary)
                                .padding(.trailing, 10)
                            Button(action: {
                                self.chosenForDelete = c
                            }, label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            })
                        }
                    }.onDelete(perform: callAlert)
                }
            }
            .navigationBarTitle("Preferences", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .alert(item: $chosenForDelete) { codeDelete in
                Alert(title: Text("Are you sure want to delete \(codeDelete.name)?"), message: Text("This action is irreversible"),
                      primaryButton: .destructive(Text("Delete"), action: {
                        self.core_driver.deleteService(uuid: codeDelete.id )
                          self.chosenForDelete = nil }),
                      secondaryButton: .cancel())
            }
            .onAppear(perform: {
                isEnableLocalKeyChain = Binding<Bool>(
                    get: {
                        let value = UserDefaults.standard.string(forKey: "isEnableLocalKeyChain")
                        return value != "false" && value != ""
                        },
                    set: { changeTo in
                        if changeTo == false {
                            UserDefaults.standard.set("", forKey: "isEnableLocalKeyChain")
                        } else {
                            withAnimation { biometricStatusChange = true }
                            UserDefaults.standard.set("true", forKey: "isEnableLocalKeyChain")
                        }
                        })
            })
    }
    

    
    func callAlert(at offset: IndexSet) {
        self.chosenForDelete = core_driver.codes[offset.first!]
    }
    
    func getWrappedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.DEBUG()
        
        return PreferencesView().environmentObject(core_driver)
    }
}
