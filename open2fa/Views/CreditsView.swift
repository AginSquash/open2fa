//
//  CreditsView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 29.04.2021.
//  Copyright © 2021 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        Form {
            Section(header: Text("License")) {
                Text("Copyright (C) 2024 Vladislav Vrublevsky vladislav.vrublevsky@gmail.com")
                Text("This software is provided 'as-is', without any express or implied warranty.")
                Text("In no event will the authors be held liable for any damages arising from the use of this software.")
                VStack(alignment: .leading) {
                    Text("Source code is available on GitHub:")
                    Link("(https://github.com/AginSquash/open2fa)", destination: URL(string: "https://github.com/AginSquash/open2fa")!)
                }
            }
            
            Section(header: Text("Privacy Policy")) {
                VStack(alignment: .leading, content: {
                    Text("In short: we do not collect or share any information.")
                    Link("(https://aginsquash.github.io/open2fa/about/privacy-policy)", destination: URL(string: "https://aginsquash.github.io/open2fa/about/privacy-policy")!)
                })
            }
            
            Section(header: Text("Acknowledgements")) {
                VStack(alignment: .leading) {
                    Text("SwiftOTP - library for generating One Time Passwords (OTP)")
                    Link("(https://github.com/lachlanbell/SwiftOTP)", destination: URL(string: "https://github.com/lachlanbell/SwiftOTP")!)
                }
                VStack(alignment: .leading) {
                    Text("CryptoSwift - Crypto related functions and helpers for Swift")
                    Link("(https://github.com/krzyzanowskim/CryptoSwift)", destination: URL(string: "https://github.com/krzyzanowskim/CryptoSwift")!)
                }
                VStack(alignment: .leading) {
                    Text("CodeScanner - SwiftUI framework for scan QR codes and barcodes")
                    Link("(https://github.com/twostraws/CodeScanner)", destination: URL(string: "https://github.com/twostraws/CodeScanner")!)
                }
            }
            
            Section(header: Text("Notes")) {
                VStack(alignment: .leading) {
                    Text("This product includes software developed by the \"Marcin Krzyzanowski\"")
                    Link("(http://krzyzanowskim.com/)", destination: URL(string: "http://krzyzanowskim.com/")!)
                }
            }
        }
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
