//
//  PreferencesView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI
import IceCream

struct PreferencesView: View {

    @EnvironmentObject var core_driver: Core2FA_ViewModel
    
    @State private var chosenForDelete: AccountCurrentCode? = nil
    @State private var isEnableLocalKeychain: Bool = false
    @State private var isEnableCloudSync: Bool = false
    
    @State private var showKeychainText: Bool = false
    @State private var showConfirmCloudSyncAlert: Bool = false
    
    var body: some View {
            Form {
                Section(header: Text("Settings")) {
                    NavigationLink(destination: ExportView(), label: { Text("Export") })
                    Toggle(isOn: $isEnableLocalKeychain) {
                        Text("Enable FaceID / TouchID")
                    }
                    .onChange(of: isEnableLocalKeychain, perform: onChangeLocalKeychain)
                    if showKeychainText {
                        Text("Please, restart app and enter password to appear change")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle(isOn: $isEnableCloudSync) {
                        Text("Enable Cloud Sync")
                    }
                    .onChange(of: isEnableCloudSync, perform: onChangeCloudSync)
                    
                    Button("Enable KC") {
                        let def = UserDefaults.standard
                        def.set(true, forKey: UserDefaultsTags.storageLocalKeychainEnable.rawValue)
                    }
                    
                    Button("Disable KC") {
                        let def = UserDefaults.standard
                        def.set(nil, forKey: UserDefaultsTags.storageLocalKeychainEnable.rawValue)
                        KeychainService.shared.removeKey()
                    }
                    
                    Button("Upload iCloud PED") {
                        core_driver.savePublicEncryptData()
                    }
                    
                    Button("Remove all PED") {
                        core_driver.removePublicEncryptData()
                    }
                    
                    Button("Clean all kc") {
                        KeychainService.shared.reset()
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
            .alert(item: $chosenForDelete, content: deletionAlert)
            .alert("This action will also delete all the saved data in iCloud",
                   isPresented: $showConfirmCloudSyncAlert) {
                Button("Cancel", role: .cancel) { self.isEnableCloudSync.toggle() }
                Button("Delete from iCloud", role: .destructive, action: disableCloud)
            }
    }
    
    init() {
        _isEnableLocalKeychain = State(initialValue: 
                                        UserDefaultsService.get(key: .storageLocalKeychainEnable))
        _isEnableCloudSync = State(initialValue: 
                                    UserDefaultsService.get(key: .cloudSync))
    }
    
    func deletionAlert(_ codeDelete: AccountCurrentCode) -> Alert {
        Alert(title: Text("Are you sure want to delete \(codeDelete.name)?"),
              message: Text("This action is irreversible"),
              primaryButton:
                .destructive(Text("Delete"), action: {
                    self.core_driver.deleteService(uuid: codeDelete.id )
                    self.chosenForDelete = nil
                }),
                secondaryButton: .cancel())
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
    
    func onChangeLocalKeychain(_ value: Bool) {
        UserDefaultsService.set(value, forKey: .storageLocalKeychainEnable)
        if !value {
            KeychainService.shared.removeKey()
        }
        showKeychainText.toggle()
    }
    
    func onChangeCloudSync(_ value: Bool) {
        if value {
            UserDefaultsService.set(true, forKey: .cloudSync)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.syncEngine = SyncEngine(objects: [
                SyncObject(type: AccountObject.self)
            ])
            appDelegate.syncEngine?.pushAll()
        } else {
            showConfirmCloudSyncAlert.toggle()
        }
    }
    
    func disableCloud() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.syncEngine = nil
        Task {
            try? await CloudKitService.removeAllAccounts()
        }
        UserDefaultsService.set(false, forKey: .cloudSync)
    }
}

extension String {
    func isNotEmpty() -> Bool {
        !self.isEmpty
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel.TestModel
        
        return PreferencesView().environmentObject(core_driver)
    }
}
