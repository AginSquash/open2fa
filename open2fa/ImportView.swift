//
//  ImportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct IVResult: Identifiable {
    let id = UUID()
    var title: String
    var Message: String
}

struct ImportView: View {
    @Environment(\.importFiles) var importAction
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
    
    @State private var isSuccessful: Bool? = nil
    @State private var error: IVResult? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Form { }
                VStack {
                    Form {
                        Section {
                            Text("If you have already used Open2FA, you can import your file using the button below.")
                            Button(action: ProccessImportAction, label: {
                                Text("Import")
                            })
                        }
                    }
                    .offset(y: geo.size.height / 2 - 100)
                }
            }
            .navigationBarTitle("Import", displayMode: .inline)
        }
    }
    
    func ProccessImportAction() {
        let type = UTType(filenameExtension: "o2fa")!
        importAction(singleOfType: [type], completion: { (result: Result<URL, Error>?) in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    if (FileManager.default.secureCopyItem(at: url.absoluteURL, to: baseURL.absoluteURL)) {
                        
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("DEBUG: \(error.localizedDescription)")
            case .none:
                return
            }
            return
        })
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ImportView()
            ImportView()
                .previewDevice("iPhone 8")
        }
    }
}
