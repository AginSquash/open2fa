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
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    
    @State private var chosenForDelete: code? = nil
    var body: some View {
            List {
                Section(header: Text("Settings")) {
                    NavigationLink(destination: ExportView(), label: { Text("Export") })
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