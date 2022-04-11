//
//  AuthView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 11.04.2022.
//  Copyright © 2022 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var serviceUUID: UUID
    
    @State private var enteredPassword: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Please, enter your password")
                TextField("Password:", text: $enteredPassword)
                Button("Unlock", action: {
                    // unlock here
                })
            }
            .padding()
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(serviceUUID: UUID())
    }
}
