//
//  PasswordEnterView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct PasswordEnterView: View {
    
    @State var isUnlocked = false
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file")
    @State private var pass = "pass"
    @State private var text = "123"
    var body: some View {
        NavigationView {
            
            NavigationLink(
                destination:
                    ContentView().environmentObject(Core2FA_ViewModel(fileURL: self.url, pass: self.pass))
                        .navigationBarTitle("")
                        .navigationBarHidden(true),
                isActive: self.$isUnlocked,
                label: {
                    Text("Hello world").onTapGesture {
                        if self.text == "123" {
                            self.isUnlocked = true
                        }
                    }
            } )
        }

    }
}


struct PasswordEnterView_Previews: PreviewProvider {
    static var previews: some View {
        return PasswordEnterView()
    }
}
