import Combine
import SwiftUI

struct NotificationsSettingsScreen: View {
    @ObservedObject var context: NotificationsSettingsScreenViewModel.Context
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                messagingSection
                if context.viewState.bindings.inAppMessagingEnabled {
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
            Text("This will reset all notification settings to their default values. Both local and push notifications will be enabled, and notification timing will be reset to 1 hour before events.")
        }
    }
    
    @ViewBuilder
    private var messagingSection: some View {
        SettingsCard(title: "Notification Settings") {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local Notifications")
                            .font(.body)
                            .foregroundColor(.onSurface)
                        Text("Event reminders and course notifications")
                            .font(.caption)
                            .foregroundColor(.onSurface.opacity(0.7))
                    }
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.inAppMessagingEnabled))
                        .tint(.primary)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Push Notifications")
                            .font(.body)
                            .foregroundColor(.onSurface)
                        Text("Updates and announcements from server")
                            .font(.caption)
                            .foregroundColor(.onSurface.opacity(0.7))
                    }
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.pushNotificationsEnabled))
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
