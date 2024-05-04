//
//  AddCodeView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 06.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
#if os(iOS) && !targetEnvironment(macCatalyst)
import AVFoundation
import CodeScanner
import UIKit
import GAuthDecrypt
#endif

struct AddCodeView: View {
    struct AlertMessage: Identifiable {
        enum AlertMsgType {
            case Error
            case Successful
        }
        
        let id: UUID
        let type: AlertMsgType
        let message: String
        
        init(_ msg: String) {
            self.id = UUID()
            self.type = .Error
            self.message = msg
        }
        
        init(type: AlertMsgType, _ msg: String) {
            self.id = UUID()
            self.type = .Error
            self.message = msg
        }
    }
    
    @StateObject var core: Core2FA_ViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name = String()
    @State private var issuer = String()
    @State private var code = String()
    @State private var alertMsg: AlertMessage? = nil
    @State private var multplieImportSuccessful: String? = nil
    @State private var showScaner = false
    @State private var isCodeScanned = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name of your account").font(.callout).padding(.top)) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Issuer").font(.callout)) {
                    TextField("Issuer", text: $issuer)
                }
                
                Section(header: Text("Your secret code").font(.callout)) {
                    TextField("Code", text: $code)
                        .foregroundColor(isCodeScanned ? .secondary : .primary)
                        .disableAutocorrection(true)
                        .disabled(isCodeScanned)
                }
                
                Section {
                    Button(action: {
                        if self.name.isEmpty {
                            self.alertMsg = AlertMessage(NSLocalizedString("Name cannot be empty", comment: "Error empty name"))
                            return
                        }
                        
                        let error = self.core.addAccount(name: self.name, issuer: self.issuer, secret: self.code)
                        if error == nil {
                            self.presentationMode.wrappedValue.dismiss()
                        } else {
                            self.alertMsg = AlertMessage(error!)
                        }
                    }, label: { Text("Save") } )
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            self.startup()
        }
        .navigationBarTitle("Adding new Account", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(item: $alertMsg) { alertMsg in
            if alertMsg.type == .Error {
                return Alert(title: Text("Alert!"), message: Text(alertMsg.message), dismissButton: .default(Text("Ok")))
            } else {
                return Alert(title: Text("Successful"), message: Text(alertMsg.message), dismissButton: .default(Text("Ok")))
            }
        }
        .sheet(isPresented: $showScaner) {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            NavigationView {
                GeometryReader { geo in
            ZStack {
                if colorScheme == .light {
                Color(.sRGB, red: 242/255, green: 242/255, blue: 247/255, opacity: 1.0)
                    .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                }
                VStack {
                        CodeScannerView(codeTypes: [.qr], simulatedData: "otpauth://totp/Test?secret=2fafa") { alertObject in
                            switch alertObject {
                            case .success(let code):
                                self.showScaner = false
                                handleCode(code: code)
                            case .failure(let alertMsg):
                                print(alertMsg.localizedDescription)
                            }
                        }
                        .frame(width: geo.size.width*0.9, height: geo.size.width*0.9, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.top)
                    
                        Text("Please scan your QR code or close this view for manual input.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    
                        Text("(◕‿◕)♡")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                            .padding()
                    
                        Spacer()
                    }
                }
                }
            .navigationBarItems(trailing: Button("Close", action: { self.showScaner = false }))
            .navigationBarTitle("Scan QR code", displayMode: .inline)
            }
            #endif
            
         }
    }
    
    func startup() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted {
            self.showScaner = false
        } else {
            self.showScaner = true
        }
        #endif
        
    }
    
    func handleCode(code: String) {
        
        ///need test code with additions
        var parsed = code
        
        if parsed.contains("otpauth://hotp/") {
            DispatchQueue.main.async {
                self.alertMsg = AlertMessage(NSLocalizedString("HOTP currently not supported!", comment: "HOTP currently not supported!"))
            }
            return
        }
        
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if parsed.contains("otpauth-migration://offline?data=") {
            let importResult = core.importFromGAuth(gauthString: parsed)
            
            DispatchQueue.main.async {
                if importResult > 0 {
                    self.alertMsg = AlertMessage(type: .Successful, "Successfuly imported \(importResult) accounts")
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    self.alertMsg = AlertMessage("Import error or this accounts already exists")
                }
            }
            
            self.isCodeScanned = true
            return
        }
        #endif
        
        parsed = parsed.replacingOccurrences(of: "otpauth://totp/", with: "")
        let index = parsed.firstIndex(of: "?")
        guard index != nil else {
            return
        }
        parsed.removeSubrange(index!...)
        parsed = parsed.replacingOccurrences(of: ":", with: " ")
        
        if let url = URL(string: code) {
            var dict = [String:String]()
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value!
                }
            }
            
            self.code = dict["secret"] ?? "Error"
            self.issuer = dict["issuer"] ?? ""
            self.name = parsed.replacingOccurrences(of: "%20", with: " ")
            self.isCodeScanned = true
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        } else {
            _debugPrint("url: \(parsed)")
            _debugPrint("QR code not a URL")
        }
        
    }
}

struct AddCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel.TestModel
        
        return AddCodeView(core: core_driver) //.environmentObject(core_driver)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
