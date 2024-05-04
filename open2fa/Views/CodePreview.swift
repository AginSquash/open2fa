//
//  CodePreview.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 05.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct CodePreview: View {
    @State private var isCopied = false
    
    let code: AccountCurrentCode
    let timeRemaning: Int
    //let progress: CGFloat
    
    var codeSingle: String {
        var codeSingle = code.currentCode
        
        codeSingle.insert(" ", at: code.currentCode.index(codeSingle.startIndex,
                                                    offsetBy: 3))
        return codeSingle
    }
    
    var timeRemaningWrapped: String {
        
        if timeRemaning < 10 {
            return "0" + String(timeRemaning)
        } else {
            return String(timeRemaning)
        }
    }
    
    func getParsedName(name: String, issuer: String) -> String {
        if issuer.isEmpty {
            return name
        }
        
        return "\(issuer) (\(name))"
    }
    
    var body: some View {
        HStack {
            if isCopied {
                Spacer()
                Text("Copied!")
                    .font(.system(size: 21))
                Spacer()
            } else {
                VStack {
                    HStack {
                        Text(getParsedName(name: code.name, issuer: code.issuer))
                        Spacer()
                    }
                    .lineLimit(1)
                    HStack {
                        Text(codeSingle)
                            .font(.system(size: 21))
                        Spacer()
                    }
                }
                .animation(.none)
            }
        }
        .contentShape(Rectangle())
        .frame(height: 40)
        .onTapGesture {
            let pasteboard = self.codeSingle.replacingOccurrences(of: " ", with: "")
            UIPasteboard.general.string = pasteboard
            withAnimation(.easeIn(duration: 0.15), { self.isCopied = true })
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                withAnimation(.easeIn(duration: 0.15), { self.isCopied = false })
            })
        }
    }
}

struct CodePreview_Previews: PreviewProvider {
    static var previews: some View {
        
        return CodePreview(code: AccountCurrentCode(id: NSUUID().uuidString, type: .TOTP, name: "Preview test", issuer: "Issuer", currentCode: "123456", creation_date: Date()), timeRemaning: 15)
        .previewLayout(.fixed(width: 300, height: 80))
    }
}
