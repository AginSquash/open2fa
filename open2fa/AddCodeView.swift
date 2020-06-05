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
    
    @State private var name = String()
    @State private var code = String()
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
                    Button(action: { }, label: { Text("Save") } )
                }
            }
            .navigationBarTitle("Adding new service", displayMode: .inline)
        }
         .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct AddCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")
        return AddCodeView().environmentObject(core_driver)
    }
}
