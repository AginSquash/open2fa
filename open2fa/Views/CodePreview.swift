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
    
    let code: code
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
    
    var body: some View {
        HStack {
            if isCopied {
                Spacer()
                Text("Copied!")
                Spacer()
            } else {
                HStack {
                    Text(code.name)
                        .padding(.leading)
                        .lineLimit(1)
                    Spacer()
                    Text(codeSingle)
                }
                .animation(.none)
            }
        }
        .contentShape(Rectangle())
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
        
        return CodePreview(code: code(id: UUID(), date: Date(), name: "Preview test", codeSingle: "123456"), timeRemaning: 15, progress: CGFloat(0.5))
        .previewLayout(.fixed(width: 300, height: 80))
    }
}
