//
//  AddCodeView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 06.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa

struct AddCodeView: View {
    @EnvironmentObject var core: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = String()
    @State private var code = String()
    @State private var error: String? = nil
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name of your service").font(.callout).padding(.top)) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Your secret code").font(.callout)) {
                    TextField("Code", text: $code)
                }
                Section {
                    Button(action: {
                        if self.name.isEmpty {
                            self.error = "Name cannot be empty"
                            return
                        }
                        
                        self.error = self.core.addService(name: self.name, code: self.code)
                        if self.error == nil {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }, label: { Text("Save") } )
                }
            }
            .navigationBarTitle("Adding new service", displayMode: .inline)
        }
         .navigationViewStyle(StackNavigationViewStyle())
        .alert(item: $error) { error in
            Alert(title: Text("Error!"), message: Text(error), dismissButton: .default(Text("Ok")))
        }
    }
}

struct AddCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")
        return AddCodeView().environmentObject(core_driver)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
