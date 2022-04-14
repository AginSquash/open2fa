//
//  ExportServiceView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 11.04.2022.
//  Copyright © 2022 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa

struct ExportServiceView: View {
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var serviceUUID: UUID
    
    @State private var secret: String = "error!"
    @State private var QRImage: Image?
    
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
                Section {
                    QRImage?
                        .resizable()
                        .scaledToFit()
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
        getQRCode(cs: code_secure)
    }
    
    func getQRCode(cs: codeSecure) {
        let exportText = "otpauth://totp/\(cs.name)?secret=\(cs.secret)"
        let encoded: Data = exportText.data(using: .utf8)!
        let params = [
            "inputMessage": encoded,
            "inputCorrectionLevel": "H"
        ] as [String : Any]
        let qrEncoder = CIFilter(name: "CIQRCodeGenerator", parameters: params)
        let ciImage: CIImage = qrEncoder!.outputImage!
        var image = UIImage(ciImage: ciImage)
        
        let size: CGSize = CGSize(width: 500, height: 500)
        UIGraphicsBeginImageContext(size);
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .none//
        image.draw(in: CGRect(origin: .zero, size: size))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        self.QRImage = Image(uiImage: image)
    }
}

struct ExportServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ExportServiceView(serviceUUID: UUID())
    }
}
