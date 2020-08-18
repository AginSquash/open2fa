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
                    .foregroundColor(Color.secondary)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: CGLineCap.round))
                    .rotationEffect(.degrees(-90))
                    .foregroundColor( progress > 0.17 ? Color.orange : Color.red)
                    .animation(.linear)
                    
            }
        }
    
}

struct TimeLeftView_Previews: PreviewProvider {
    static var previews: some View {
        TimeLeftView(progress: 0.4)
            .frame(width: 30, height: 30, alignment: .center)
            .previewLayout(.fixed(width: 40, height: 40))
    }
}
