//
//  PreferencesView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    
    @AppStorage("isEnableLocalKeyChain") var storageLocalKeyChain: String = ""
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    
    @State private var chosenForDelete: AccountCurrentCode? = nil
    @State private var biometricStatusChange: Bool = false
    @State private var isEnableLocalKeyChain = Binding<Bool>(get: { false }, set: { _ in})
    
    let fileName = "encrypted.o2fa"
    
    var body: some View {
            Form {
                Section(header: Text("Settings")) {
                    NavigationLink(destination: ExportView(), label: { Text("Export") })
                    Toggle(isOn: isEnableLocalKeyChain) {
                        Text("Enable FaceID / TouchID")
                    }
                    if biometricStatusChange {
                        Text("Please, restart app and enter password to appear change")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Enable KC") {
                        let def = UserDefaults.standard
                        def.set(true, forKey: UserDefaultsTags.storageLocalKeychainEnable.rawValue)
                    }
                    
                    NavigationLink(
                        destination: CreditsView(),
                        label: {
                            Text("Credits")
                        })
                }
                Section(header: Text("Share & Edit"), footer:
                    Group {
                    #if os(iOS) && !targetEnvironment(macCatalyst)
                        Text("Tap to share or edit, swipe from right edge to the left to ")
                        +
                        Text("delete").foregroundColor(.red)
                    #endif
                }.layoutPriority(1)
                ) {
                    ForEach(Array(core_driver.codes.enumerated()), id: \.element) { index, c in
                        HStack {
                            VStack(alignment: .leading) {
                                if c.issuer.isNotEmpty() {
                                    Text(c.issuer)
                                }
                                Text(c.name)
                                Text(self.getWrappedDate(date: c.creation_date))
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 10)
                            }
                            Spacer()
                            NavigationLink(
                                destination:
                                    EditCodeView(service: c),
                                label: {
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20)
                            }).frame(width: 40)
                        }
                        .swipeActions {
                            Button(action: {
                                callAlert(at: index)
                            }) {
                                Text("Delete")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            .padding([.top], 1)
            .navigationBarTitle("Preferences", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .alert(item: $chosenForDelete) { codeDelete in
                Alert(title: Text( NSLocalizedString("Are you sure want to delete", comment: "delete verification") + " \(codeDelete.name)?"), message: Text("This action is irreversible"),
                      primaryButton: .destructive(Text("Delete"), action: {
                        self.core_driver.deleteService(uuid: codeDelete.id )
                          self.chosenForDelete = nil }),
                      secondaryButton: .cancel())
            }
            .onAppear(perform: {
                isEnableLocalKeyChain = Binding<Bool>(
                    get: {
                        let value = UserDefaults.standard.string(forKey: UserDefaultsTags.storageLocalKeychainEnable.rawValue)
                        return value != "false" && value != ""
                        },
                    set: { changeTo in
                        if changeTo == false {
                            UserDefaults.standard.set("false", forKey: "isEnableLocalKeyChain")
                            deletePasswordKeychain(name: fileName)
                            KeychainWrapper.shared.removeKey()
                        } else {
                            withAnimation { biometricStatusChange = true }
                            UserDefaults.standard.set("true", forKey: "isEnableLocalKeyChain")
                        }
                        })
            })
    }
    

    
    func callAlert(at offset: Int) {
        self.chosenForDelete = core_driver.codes[offset]
    }
    
    func getWrappedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    
    }
}

extension String {
    func isNotEmpty() -> Bool {
        !self.isEmpty
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_file"), pass: "pass")

        core_driver.DEBUG()
        
        return PreferencesView().environmentObject(core_driver)
    }
}
