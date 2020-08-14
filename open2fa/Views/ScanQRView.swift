//
//  ScanQRView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 14.08.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import CodeScanner

struct ScanQRView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            CodeScannerView(codeTypes: [.qr], simulatedData: "{some json}", completion: self.scan)
                .navigationBarItems(trailing: Button("Close", action: { self.presentationMode.wrappedValue.dismiss() }))
                .navigationBarTitle("Scan QR code", displayMode: .inline)
        }
        .highPriorityGesture(DragGesture())
    }
    
    func scan(result: Result<String, CodeScannerView.ScanError>) {
        
    }
}

struct ScanQRView_Previews: PreviewProvider {
    static var previews: some View {
        ScanQRView()
    }
}
