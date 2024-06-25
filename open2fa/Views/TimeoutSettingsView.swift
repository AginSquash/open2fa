//
//  TimeoutSettingsView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 03.06.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct TimeoutSettingsView: View {
    @AppStorage(AppSettings.SettingsKeys.lockTimeout.rawValue) var lockTimeout: Double = 60.0
    
    var body: some View {
        Form {
            Section(header: Text("Session timeout")) {
                ForEach(AppSettings.possibleLockTimeout, id: \.self) { time in
                    HStack {
                        Text(time == 0.0 ? "Immediately" : "\(Int(time)) seсonds")
                        Spacer()
                        if time == lockTimeout {
                            Image(systemName: "checkmark")
                                .renderingMode(.template)
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        lockTimeout = time
                    }
                }
            }
        }
    }
}

#Preview {
    TimeoutSettingsView()
}
