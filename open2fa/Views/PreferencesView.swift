//
//  PreferencesView.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 17.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {

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
                    .onChange(of: viewModel.isEnableLocalKeychain, perform: viewModel.onChangeLocalKeychain)
                    if viewModel.showKeychainText {
                        Text("Please, restart app and enter password to appear change")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle(isOn: $viewModel.isEnableCloudSync) {
                        Text("Enable Cloud Sync")
                    }
                    .onChange(of: viewModel.isEnableCloudSync, perform: viewModel.onChangeCloudSync)
                    .disabled(!viewModel.cloudSyncAvailable)
                    
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
                   isPresented: $viewModel.showConfirmCloudSyncAlert) {
                Button("Cancel", role: .cancel, action: viewModel.toggleBackCloud)
                Button("Delete from iCloud", role: .destructive, action: viewModel.disableCloud)
            }
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

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        let core_driver = Core2FA_ViewModel.TestModel
        
        return PreferencesView().environmentObject(core_driver)
    }
}
