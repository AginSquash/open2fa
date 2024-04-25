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
    
    var serviceUUID: String
    
    @State private var secret: String = "error!"
    @State private var QRImage: Image?
    @Binding var isCloseExport: Bool
    
    var verticalPadding: CGFloat {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        return -20
        #endif
        return 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                Form {
                    Section(header: Text("Your secret code").font(.callout)) {
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
                    Section(header: Text("QR code")) {
                        HStack {
                            Spacer()
                            QRImage?
                                .resizable()
                                .scaledToFit()
                                .frame(height: geometry.size.height/2, alignment: .center)
                                .padding(.vertical, verticalPadding)
                            Spacer()
                        }
                    }
                }
                .navigationTitle(Text("Exporting an Account"))
                .navigationViewStyle(StackNavigationViewStyle())
                .onAppear(perform: startup)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.isCloseExport = true
                            self.presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("Close")
                        })
                    }
                })
            }
        }
    }
    
    func startup() {
        guard let code_secure = core_driver.NoCrypt_ExportService(with: serviceUUID) else {
            fatalError("Auth with incorrect pass/other")
        }
        
        self.secret = code_secure.secret.base32EncodedString
        getQRCode(cs: code_secure)
    }
    
    func getQRCode(cs: AccountData) {
        let name = cs.name.replacingOccurrences(of: " ", with: "%20")
        let secret = cs.secret.base32EncodedString
        var exportText = "otpauth://totp/\(name)?secret=\(secret)"
        if cs.issuer.isNotEmpty() {
            exportText.append("&issuer=\(cs.issuer)")
        }
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
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.DEBUG()
        let firstID = "somerandomID" //core_driver.codes.first!.id
        
        return ExportServiceView(serviceUUID: firstID, isCloseExport: .constant(false)).environmentObject(core_driver)
    }
}
