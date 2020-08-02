//
//  ImportView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 24.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.importFiles) var importAction
    
    let fileName = "encrypted.o2fa"
    var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! .appendingPathComponent(fileName)
    }
    
    var body: some View {
        Text("Import view")
            .onTapGesture(count: 1, perform:ProccessImportAction)
    }
    
    func ProccessImportAction() {
        let type = UTType(filenameExtension: "o2fa")!
        importAction(singleOfType: [type], completion: { (result: Result<URL, Error>?) in
            switch result {
            case .success(let url):
                url.startAccessingSecurityScopedResource()
                print("DEBUG: \(url)")
                print("DEBUG: absoluteURL    \(url.absoluteURL)")
                print("DEBUG: absoluteString \(url.absoluteString)")
                print("DEBUG: path           \(url.path)")
                print("DEBUG: isReadableFile \(FileManager.default.isReadableFile(atPath: url.path))")
                
                //let data: Data
                
                //data = try! Data(contentsOf: URL(string: url.path)!)
                //try! data.write(to: baseURL.absoluteURL, options: .atomic)
                print("DEBUG:  \(FileManager.default.secureCopyItem(at: url.absoluteURL, to: baseURL.absoluteURL))")
                print("DEBUG: Copyed!")
                url.stopAccessingSecurityScopedResource()
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
        ImportView()
    }
}
