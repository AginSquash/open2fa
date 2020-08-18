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
    
        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: 5.0)
                    .opacity(0.3)
                    .foregroundColor(Color.red)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: CGLineCap.round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear)
                    .foregroundColor(Color.red)
            }
        }
    
    init(progress: CGFloat) {
        self.progress = progress
        _debugPrint("TimeLeftView \(Date())")
    }
    
}

struct TimeLeftView_Previews: PreviewProvider {
    static var previews: some View {
        TimeLeftView(progress: 0.4)
            .frame(width: 300, height: 300, alignment: .center)
    }
}
