//
//  PreferencesView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(AppSettings.SettingsKeys.lockTimeout.rawValue) var lockTimeout: Double = 60.0
    
    @EnvironmentObject var core_driver: Core2FA_ViewModel
    @StateObject private var viewModel = PreferencesViewModel()
    
    @State private var chosenForDelete: AccountCurrentCode? = nil
    
    var body: some View {
            Form {
                Section(header: Text("Settings")) {
                    NavigationLink(destination: ExportView(), label: { Text("Export") })
                    Toggle(isOn: $viewModel.isEnableLocalKeychain) {
                        Text("Enable FaceID / TouchID")
                    }
                    .onChange(of: viewModel.isEnableLocalKeychain) { value in
                        viewModel.onChangeLocalKeychain(value, core: core_driver)
                    }
                    NavigationLink(destination: ChangePasswordView().environmentObject(core_driver)) {
                        Text("Change password")
                    }
                    if core_driver.needsSecurityUpgrade {
                        NavigationLink(destination: SecurityUpgradeView().environmentObject(core_driver)) {
                            Text("Upgrade encryption")
                        }
                    }
                    if viewModel.showKeychainText {
                        Text("Please, restart app and enter password to appear change")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle(isOn: $viewModel.isEnableCloudSync) {
                        Text("Enable Cloud Sync")
                    }
                    .onChange(of: viewModel.isEnableCloudSync, perform: viewModel.onChangeCloudSync)
                    .disabled(!viewModel.cloudSyncAvailable)
                    
                    NavigationLink(destination: TimeoutSettingsView()) {
                        HStack {
                            Text("Session timeout")
                            Spacer()
                            Text(lockTimeout == 0.0 ? "Immediately" : "\(Int(lockTimeout)) sec.")
                        }
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
                                    EditCodeView(service: c)
                                    .environmentObject(core_driver),
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
#if os(iOS) && !targetEnvironment(macCatalyst)
            .padding([.top], 1)
#endif
            .navigationBarTitle("Preferences", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .alert(item: $chosenForDelete, content: deletionAlert)
            .alert("Warning!",
                   isPresented: $viewModel.showConfirmCloudSyncAlert,
                   actions: {
                    Button("Cancel", role: .cancel, action: viewModel.toggleBackCloud)
                    Button("Delete from iCloud", role: .destructive, action: viewModel.disableCloud)
                    },
                   message: {
                    Text("This action will also delete all the saved data in iCloud")
            })
            .alert("Found iCloud data",
                   isPresented: $viewModel.showDeleteCloudAlert,
                   actions: {
                Button("Cancel", role: .cancel, action: viewModel.toggleBackCloud)
                Button("Delete data from iCloud", role: .destructive,
                       action: viewModel.deleteFromCloudAndEnableSync)
                    },
                   message: {
                Text("You already have data in iCloud. To continue, you must delete the data from the cloud.")
            })
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
}

extension String {
    func isNotEmpty() -> Bool {
        !self.isEmpty
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var core: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var errorMessage: String?
    @State private var working = false

    var body: some View {
        Form {
            Section {
                SecureField("Current password", text: $current)
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirm)
                if !newPassword.isEmpty, let reason = PasswordPolicy.rejectionReason(newPassword) {
                    Text(LocalizedStringKey(reason))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            Section {
                Button(action: submit, label: {
                    HStack {
                        Spacer()
                        if working {
                            ProgressView()
                        } else {
                            Text("Change password")
                        }
                        Spacer()
                    }
                })
                .disabled(working || current.isEmpty || newPassword != confirm || PasswordPolicy.rejectionReason(newPassword) != nil)
            }
        }
        .navigationBarTitle("Change password", displayMode: .inline)
        .alert(isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }

    private func submit() {
        guard !working else { return }
        working = true
        let currentPassword = current
        let replacement = newPassword
        Task {
            do {
                try await core.changePassword(current: currentPassword, newPassword: replacement)
                presentationMode.wrappedValue.dismiss()
            } catch let error as VaultUnlockError {
                errorMessage = error.userFacingMessage
            } catch {
                errorMessage = "Unexpected error"
            }
            working = false
        }
    }
}

struct SecurityUpgradeView: View {
    @EnvironmentObject var core: Core2FA_ViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var password = ""
    @State private var errorMessage: String?
    @State private var working = false

    var body: some View {
            Form {
                Section {
                    Text("Your vault still uses a weak key derivation. Enter your password to re-encrypt it.")
                    SecureField("Password", text: $password)
                }
                Section {
                    Button(action: submit, label: {
                        HStack {
                            Spacer()
                            if working { ProgressView() } else { Text("Upgrade encryption") }
                            Spacer()
                        }
                    })
                    .disabled(working || password.isEmpty)
                    Button("Not now") {
                        core.deferSecurityUpgrade = true
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationBarTitle("Upgrade encryption", displayMode: .inline)
            .alert(isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
            }
    }

    private func submit() {
        guard !working else { return }
        working = true
        let entered = password
        Task {
            do {
                try await core.upgradeEncryption(password: entered)
                presentationMode.wrappedValue.dismiss()
            } catch let error as VaultUnlockError {
                errorMessage = error.userFacingMessage
            } catch {
                errorMessage = "Unexpected error"
            }
            working = false
        }
    }
}

extension VaultUnlockError {
    var userFacingMessage: String {
        switch self {
        case .wrongPassword:
            return NSLocalizedString("Password is incorrect", comment: "")
        case .weakPassword(let key):
            return NSLocalizedString(key, comment: "")
        case .needsRecovery:
            return NSLocalizedString("Vault check data is missing. Restore from an export instead of creating a new password.", comment: "")
        case .incompleteVault:
            return NSLocalizedString("Could not decrypt every account. Encryption was not changed.", comment: "")
        case .keyNotSaved:
            return NSLocalizedString("Please enter your password for further login with Face ID", comment: "")
        case .cryptoFailure:
            return NSLocalizedString("Unexpected error", comment: "")
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel.TestModel
        
        return PreferencesView().environmentObject(core_driver)
    }
}
