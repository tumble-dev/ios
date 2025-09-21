//
//  AccountScreen.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import SwiftUI
import Combine

struct AccountScreen: View {
    
    @ObservedObject var context: AccountScreenViewModel.Context
    
    var body: some View {
        ZStack {
            switch context.viewState.userState {
            case .loading:
                InfoView.loading("Loading account...")
            case .error(let msg):
                InfoView.error(title: "Could not load your account", subtitle: msg)
            case .missing:
                // TODO: Add action to navigate to settings screen
                InfoView.empty(
                    title: "You have no connected accounts",
                    subtitle: "Connect one or more accounts from the settings screen",
                    icon: "person.crop.circle.fill.badge.xmark"
                )
            case .loaded(let user):
                switch context.viewState.dataState {
                case .loaded(let events, let bookings):
                    Text("Success!")
                default:
                    Text("")
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    context.send(viewAction: .close)
                }
            }
        }
        .background(Color.background)
    }
}
