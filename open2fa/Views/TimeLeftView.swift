//
//  TimeLeftView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 18.08.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct TimeLeftView: View {
    let progress: CGFloat
    
    var currentColor: Color {
        if #available(iOS 15.0, *) { /// bug in ios 15? (trim + stroke + dynamic color change)
            return Color.orange
        }
        
        if progress > 0.17 {
            return Color.orange
        }
        return Color.red
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5.0)
                .opacity(0.3)
                .foregroundColor(Color.secondary)
                .animation(.none)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(currentColor, style: StrokeStyle(lineWidth: 5.0, lineCap: CGLineCap.round))
                .animation(.linear)
                .rotationEffect(.degrees(-90))
                
        }
    }
    
}

struct TimeLeftView_Previews: PreviewProvider {
    static var previews: some View {
        TimeLeftView(progress: 0.2)
            .frame(width: 30, height: 30, alignment: .center)
            .previewLayout(.fixed(width: 40, height: 40))
    }
}
