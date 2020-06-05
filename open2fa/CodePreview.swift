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
    let code: code
    let timeRemaning: Int
    
    var codeSingle: String {
        var old_codeSingle = code.codeSingle
        var new_codeSingle = String()
        for _ in 0..<3 {
            new_codeSingle.append( old_codeSingle.removeFirst() )
        }
        new_codeSingle.append(" ")
        new_codeSingle.append(contentsOf: old_codeSingle)
        return new_codeSingle
    }
    
    var body: some View {
        HStack {
            Text(String(timeRemaning))
                .foregroundColor(.secondary)
            Text(code.name)
            Spacer()
            Text(codeSingle)
        }
    .padding()
    }
}

struct CodePreview_Previews: PreviewProvider {
    static var previews: some View {
        
        return CodePreview(code: code(id: UUID(), date: Date(), name: "Preview test", codeSingle: "123456"), timeRemaning: 10)
        .previewLayout(.fixed(width: 300, height: 80))
    }
}
