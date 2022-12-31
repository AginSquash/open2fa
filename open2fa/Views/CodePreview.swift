//
//  CodePreview.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 05.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import core_open2fa

struct CodePreview: View {
    @State private var isCopied = false
    
    let code: Account_Code
    let timeRemaning: Int
    let progress: CGFloat
    
    var codeSingle: String {
        guard code.codeSingle != nil else {
            return "Incorrect password"
        }
        var old_codeSingle = code.codeSingle!
        var new_codeSingle = String()
        for _ in 0..<3 {
            new_codeSingle.append( old_codeSingle.removeFirst() )
        }
        new_codeSingle.append(" ")
        new_codeSingle.append(contentsOf: old_codeSingle)
        return new_codeSingle
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
        
        return CodePreview(code: Account_Code(id: UUID(), date: Date(), name: "Preview test", issuer: "Issuer", codeSingle: "123456"), timeRemaning: 15, progress: CGFloat(0.5))
        .previewLayout(.fixed(width: 300, height: 80))
    }
}
