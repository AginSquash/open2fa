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
    
    @State private var secret: String = "error!"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your service secret:").font(.callout)) {
                    HStack {
                        Text(secret)
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = secret
                        }, label: {
                            Image(systemName: "doc.on.doc")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                        })
                    }
                }
            }
            .navigationTitle(Text("Export Service"))
            .onAppear(perform: startup)
        }
    }
    
    func startup() {
        guard let code_secure = core_driver._exportServiceSECURE(with: serviceUUID) else {
            fatalError("Auth with incorrect pass/other")
        }
        
        self.secret = code_secure.secret
    }
}

struct ExportServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ExportServiceView(serviceUUID: UUID())
    }
}
