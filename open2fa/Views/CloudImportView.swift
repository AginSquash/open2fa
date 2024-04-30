//
//  CloudImportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 30.04.2024.
//  Copyright © 2024 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct CustomButton: View {
    
    var body: some View {
       Text("Text")
    }
}

struct CloudImportView: View {
    let deleteHandler: ()->()
    let restoreHandler: ()->()
    let disableHandler: ()->()
    
    @Environment(\.dismiss) var dismiss
    @State private var maxWidth: CGFloat = .zero
    @State private var isShowDeleteAlert: Bool = false
    
    var body: some View {
        VStack {
            HStack {
               /* Text("☁️")
                    .font(.largeTitle) */
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                    .font(.largeTitle)
                Text("iCloud")
                    .font(.title)
                    .padding(.bottom, 1)
            }
            Group {
                Text("Open2FA data has been found in iCloud.\nYou can:\n - Delete them and start from scratch.\n - Restore the data from iCloud & enable sync\n - Disable iCloud sync on this device.")
            }
            .padding(.horizontal, 0)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            Group {
                HStack {
                    Button(action: { self.isShowDeleteAlert = true }, label: {
                        Text("Delete")
                            .frame(maxWidth: .infinity)
                            .background(rectReader($maxWidth))
                    })
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .padding(.trailing, 2)
                    Button(action: restoreCloud, label: {
                        Text("Restore")
                            .frame(maxWidth: .infinity)
                    })
                        .buttonStyle(.borderedProminent)
                        .padding(.leading, 2)
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal)
            
            Button(action: disableCloud, label: {
                Text("Disable sync")
                    .background(rectReader($maxWidth))
                    //.frame(maxWidth: .infinity)
                    .frame(width: maxWidth)
            })
            .buttonStyle(.bordered)
            .padding(.horizontal)
            
        }
        .interactiveDismissDisabled()
        .alert("Are you sure?\nThis action is irreversible",
               isPresented: $isShowDeleteAlert, actions: {
            Button("Cancel", role: .cancel, action: { })
            Button("Delete", role: .destructive, action: deleteCloud)
        })
    }
    
    // helper reader of view intrinsic width
    private func rectReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { gp -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = max(binding.wrappedValue, gp.frame(in: .local).width)
            }
            return Color.clear
        }
    }
    
    func deleteCloud() {
        deleteHandler()
        dismiss()
    }
    
    func restoreCloud() {
        restoreHandler()
        dismiss()
    }
    
    func disableCloud() {
        disableHandler()
        dismiss()
    }
}

#Preview {
    CloudImportView(deleteHandler: { }, restoreHandler: { }, disableHandler: { })
}
