//
//  AddCodeView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 06.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa
#if os(iOS)
import AVFoundation
import CarBode
#endif

struct AddCodeView: View {
    @EnvironmentObject var core: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = String()
    @State private var code = String()
    @State private var error: String? = nil
    @State private var showScaner = false
    @State private var isCodeScanned = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name of your service").font(.callout).padding(.top)) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Your secret code").font(.callout)) {
                    TextField("Code", text: $code)
                        .foregroundColor(isCodeScanned ? .secondary : .primary)
                        .disabled(isCodeScanned)
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
            .navigationBarHidden(true)
        }
        .onAppear {
            self.startup()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(item: $error) { error in
            Alert(title: Text("Error!"), message: Text(error), dismissButton: .default(Text("Ok")))
        }
        .sheet(isPresented: $showScaner) {
            #if os(iOS)
            NavigationView {
                
                CBScanner(supportBarcode: [.qr])
                            .interval(delay: 5.0) //Event will trigger every 5 seconds
                            .found { code in
                                self.showScaner = false
                                handleCode(code: code)
                            }
                    .simulator(mockBarCode: "otpauth://totp/Test?secret=2fafa")
                    
                .navigationBarItems(trailing: Button("Close", action: { self.showScaner = false }))
                .navigationBarTitle("Scan QR code", displayMode: .inline)
            }
            #endif
         }
    }
    
    func startup() {
        #if targetEnvironment(macCatalyst)
        return 
        #endif
        #if os(iOS)
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
        parsed = parsed.replacingOccurrences(of: "otpauth://totp/", with: "")
        parsed = parsed.replacingOccurrences(of: "otpauth://hotp/", with: "")
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
            self.name = parsed
            self.isCodeScanned = true
            
        } else { fatalError("QR code not a URL") }
        
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
