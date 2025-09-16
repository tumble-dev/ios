//
//  AccountPageView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-25.
//

import SwiftUI

struct Account: View {
    
    @ObservedObject var viewModel: AccountViewModel
    @ObservedObject var appController: AppController = .shared
    
    @State private var isSigningOut: Bool = false
        
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                switch viewModel.authStatus {
                case .authorized:
                    UserOverview(viewModel: viewModel)
                case .unAuthorized:
                    AccountLogin(isAddAccount: false)
                }
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            .navigationBarTitleDisplayMode(.inline)
            .if(viewModel.authStatus == .authorized) { view in
                view.navigationTitle(NSLocalizedString("Account", comment: ""))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.authStatus == .authorized {
                        SignOutButton(showConfirmationDialog: {
                            isSigningOut = true
                        })
                        .confirmationDialog(LocalizedStringKey("Are you sure you want to log out of your account?"), isPresented: $isSigningOut, actions: {
                            Button(LocalizedStringKey("Yes"), action: logOut)
                        }, message: {
                            Text(LocalizedStringKey("Are you sure you want to log out of your account?"))
                        })
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    SettingsButton()
                }
            }
            
        }
        .tag(TabbarTabType.account)
    }
    
    func logOut() {
        Task {
            await viewModel.logOut()
        }
    }
}
