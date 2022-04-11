//
//  ExportServiceView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 11.04.2022.
//  Copyright © 2022 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct ExportServiceView: View {
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var serviceUUID: UUID
    
    @State private var showAuth: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your service secret:").font(.callout)) {
                    HStack {
                        Text("1234567")
                        Spacer()
                        Button(action: {
                            //copy to clipboard
                        }, label: {
                            Image(systemName: "doc.on.doc")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                        })
                    }
                }
            }.navigationTitle(Text("Export Service"))
        }
    }
}

struct ExportServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ExportServiceView(serviceUUID: UUID())
    }
}
