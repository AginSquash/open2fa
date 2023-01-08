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
    
    var service: Account_Code
    
    @State private var name = String()
    @State private var issuer = String()
    @State private var error: String? = nil
    @State private var deleteThisService = false
    
    @State private var showAuth: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name of your account").font(.callout).padding(.top)) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Issuer").font(.callout)) {
                    TextField("Issuer", text: $issuer)
                }
                
                Section(header: Text("Your secret code").font(.callout), footer: Text(NSLocalizedString("Created on", comment: "Creation date") + " \(getParsedDate(date: service.date))")) {
                    HStack {
                        Image(systemName: "circle.fill")
                        Image(systemName: "circle.fill")
                        Image(systemName: "circle.fill")
                        Image(systemName: "circle.fill")
                        
                        Spacer()
                        
                        Button(action: showSecret,
                               label: {
                                    Image(systemName: "eye.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 20)
                                    }
                        )
                    }
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
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
        .sheet(isPresented: $showAuth, content: {
            AuthView(serviceUUID: service.id)
        })
    }
    
    var deleteButton: some View {
        Button(
            action: { self.deleteThisService = true },
            label: {
                Text("Delete")
                    .foregroundColor(.red)
            })
            .alert(isPresented: $deleteThisService) {
                Alert(title: Text(NSLocalizedString("Are you sure want to delete", comment: "delete verification") + " \(name)?"), message: Text("This action is irreversible"),
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
                self.error = NSLocalizedString("Name cannot be empty", comment: "Error empty name")
                return
            }
            
            guard (self.name != self.service.name) || (self.issuer != self.service.issuer) else {
                self.presentationMode.wrappedValue.dismiss()
                return
            }
            
            let parsed_issuer = issuer.trimmingCharacters(in: .whitespaces)
            
            self.error = self.core_driver.editAccount(serviceID: service.id, newName: self.name, newIssuer: parsed_issuer)
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
    
    func showSecret() {
        self.showAuth = true
    }
    
    init(service: Account_Code) {
        self.service = service
        
        self._name = State(wrappedValue: service.name)
        self._issuer = State(wrappedValue: service.issuer)
    }
    
    func getParsedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        
        return dateFormatter.string(from: date)
    }
}

struct EditCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.DEBUG()
        
        return EditCodeView(service: core_driver.codes.first!).environmentObject(core_driver)
    }
}
