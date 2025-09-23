import Combine
import SwiftUI

struct NotificationsSettingsScreen: View {
    @ObservedObject var context: NotificationsSettingsScreenViewModel.Context
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                messagingSection
                if context.viewState.bindings.notificationsEnabled {
                    notificationOffsetSection
                }
                resetSection
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingL)
        }
        .background(Color.background)
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                context.send(viewAction: .resetAllSettings)
            }
        } message: {
            Text("This will reset all advanced settings to their default values. This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private var messagingSection: some View {
        SettingsCard(title: "Notifications") {
            VStack(spacing: 0) {
                HStack {
                    Text("In-App Messaging")
                        .font(.body)
                        .foregroundColor(.onSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.inAppMessagingEnabled))
                        .tint(.primary)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                HStack {
                    Text("Notifications")
                        .font(.body)
                        .foregroundColor(.onSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.notificationsEnabled))
                        .tint(.primary)
                }
                .padding(.vertical, .spacingM)
            }
        }
    }
    
    @ViewBuilder
    private var notificationOffsetSection: some View {
        SettingsCard(title: "Timing") {
            HStack {
                Text("Notification Offset")
                    .font(.body)
                    .foregroundColor(.onSurface)
                Spacer()
                Picker("Notification Offset", selection: context.viewState.bindings.binding(for: \.notificationOffset)) {
                    ForEach(NotificationOffset.allCases, id: \.self) { offset in
                        Text(offset.displayName).tag(offset)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.vertical, .spacingM)
        }
    }
    
    @ViewBuilder
    private var resetSection: some View {
        SettingsCard(title: "Reset") {
            SettingsButton(title: "Reset All Notification Settings", style: .destructive) {
                showingResetAlert = true
            }
            .padding(.vertical, .spacingM)
        }
    }
}
