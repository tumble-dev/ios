//
//  NotificationPermissionsScreen.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import SwiftUI

/// A prompt that asks the user whether they would like to enable Notifications or not.
struct NotificationPermissionsScreen: View {
    @ObservedObject var context: NotificationPermissionsScreenViewModel.Context
    
    var body: some View {
        VStack {
            mainContent
        }
        .overlay {
            buttons
        }
        .background()
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 8) {
            Text("Allow notifications and never miss an important event")
                .font(.system(.headline))
                .multilineTextAlignment(.center)
            
            Text("You can change your settings later.")
                .font(.system(.subheadline))
                .multilineTextAlignment(.center)
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            Button("Ok") { context.send(viewAction: .enable) }
            
            Button { context.send(viewAction: .notNow) } label: {
                Text("Not now")
                    .padding(14)
            }
        }
    }
}
