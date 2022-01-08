//
//  EditCodeView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 07.01.2022.
//  Copyright © 2022 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa
import XCTest

struct EditCodeView: View {
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var service: code
    
    @State private var name = String()
    @State private var error: String? = nil
    
    @State private var deleteThisService = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name of your account").font(.callout).padding(.top)) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Your secret code").font(.callout), footer: Text("Created on \(service.date)")) {
                    HStack {
                        Image(systemName: "circle.fill")
                        Image(systemName: "circle.fill")
                        Image(systemName: "circle.fill")
                        Image(systemName: "circle.fill")
                    }
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
                    .disabled(true)
                }
                
                Section {
                    saveButton
                }
            }
            .navigationBarHidden(true)
        } // leading: Spacer().frame(width: 20) <- use to hide "Preferences" back button
        .navigationBarItems(trailing: deleteButton)
        .navigationBarTitle("Account editing", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(item: $error) { error in
            Alert(title: Text("Error!"), message: Text(error), dismissButton: .default(Text("Ok")))
        }
    }
    
    var deleteButton: some View {
        Button(
            action: { self.deleteThisService = true },
            label: {
                Text("Delete")
                    .foregroundColor(.red)
            })
            .alert(isPresented: $deleteThisService) {
                Alert(title: Text("Are you sure want to delete \(name)?"), message: Text("This action is irreversible"),
                      primaryButton: .destructive(Text("Delete"), action: {
                        self.core_driver.deleteService(uuid: service.id )
                        self.presentationMode.wrappedValue.dismiss()
                }),
                      secondaryButton: .cancel())
            }
    }
    
    var saveButton: some View {
        Button(action: {
            if self.name.isEmpty {
                self.error = "Name cannot be empty"
                return
            }
            
            guard self.name != self.service.name else {
                return
            }
            
            self.error = self.core_driver.editService(serviceID: service.id, newName: self.name)
            if self.error == nil {
                self.presentationMode.wrappedValue.dismiss()
            }
        }, label: {
            HStack {
                Spacer()
                Text("Save")
                Spacer()
            }
        } )
    }
    
    /// Custom back button
    /*
    var backButton: some View {
        Button(
            action: { self.presentationMode.wrappedValue.dismiss() },
            label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                    Text("Back")
                }
        })
    }
     */
    
    init(service: code) {
        self.service = service
        
        self._name = State(wrappedValue: service.name)
    }
}

struct EditCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.DEBUG()
        
        return EditCodeView(service: core_driver.codes.first!).environmentObject(core_driver)
    }
}
