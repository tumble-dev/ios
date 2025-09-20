//
//  NotificationsSettingsScreen.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import SwiftUI
import Combine

struct NotificationsSettingsScreen: View {
    
    @ObservedObject var context: NotificationsSettingsScreenViewModel.Context
    @State private var showingResetAlert = false
    
    var body: some View {
        Form {
            messagingSection
            if context.viewState.bindings.notificationsEnabled {
                notificationOffsetSection
            }
            resetSection
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                context.send(viewAction: .resetAllSettings)
            }
        } message: {
            Text("This will reset all advanced settings to their default values. This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private var messagingSection: some View {
        Section {
            Toggle("In-App Messaging", isOn: context.viewState.bindings.binding(for: \.inAppMessagingEnabled))
            Toggle("Notifications", isOn: context.viewState.bindings.binding(for: \.notificationsEnabled))
            
        } header: {
            Text("Notifications")
        } footer: {
            Text("Control what kind of notifications you will be able to receive.")
        }
    }
    
    @ViewBuilder
    private var notificationOffsetSection: some View {
        Section {
            Picker("Notification Offset", selection: context.viewState.bindings.binding(for: \.notificationOffset)) {
                ForEach(NotificationOffset.allCases, id: \.self) { offset in
                    Text(offset.displayName).tag(offset)
                }
            }
        } header: {
            Text("Timing")
        } footer: {
            Text("Settings for how soon you should receive a notification before a certain event.")
        }
    }
    
    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button("Reset All Notification Settings") {
                showingResetAlert = true
            }
            .foregroundColor(.red)
            
        } footer: {
            Text("Reset all advanced settings to their default values.")
        }
    }
}
