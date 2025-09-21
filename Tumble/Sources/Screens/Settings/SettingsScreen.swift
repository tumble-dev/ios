//
//  SettingsScreen.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import SwiftUI
import Combine
import SwiftUIIntrospect

struct SettingsScreen: View {
    
    @ObservedObject var context: SettingsScreenViewModel.Context
    @State private var showingRemoveAccountAlert = false
    
    var body: some View {
        Form {
            accountSection
            generalSection
            supportSection
            advancedSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    context.send(viewAction: .close)
                }
            }
        }
        .alert("Remove Account", isPresented: $showingRemoveAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                context.send(viewAction: .removeAccount)
            }
        } message: {
            Text("This will sign you out of Kronox. Any notifications you had set for bookings or exams will be cleared.")
        }
    }
    
    @ViewBuilder
    private var accountSection: some View {
        Section {
            if let currentUser = context.viewState.bindings.currentUser {
                HStack {
                    UserAvatar(name: currentUser.name, size: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser.name)
                            .font(.headline)
                        Text(currentUser.username)
                            .font(.caption)
                            .foregroundColor(.onSurface)
                        Text(currentUser.school.uppercased())
                            .font(.caption2)
                            .foregroundColor(.onSurface.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                if context.viewState.bindings.allUsers.count > 1 {
                    Picker("User", selection: context.viewState.bindings.binding(for: \.activeUsername)) {
                        ForEach(context.viewState.bindings.allUsers, id: \.username) { user in
                            Text(user.name).tag(user.username)
                        }
                    }
                }
                
                Button("Add Account") {
                    context.send(viewAction: .addAccount)
                }
                
                Button("Log Out") {
                    showingRemoveAccountAlert = true
                }
                .foregroundColor(.red)
                
            } else {
                HStack {
                    Image(systemName: "person.crop.circle.badge.exclam")
                        .foregroundColor(.onSurface)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No accounts added")
                            .font(.headline)
                            .foregroundColor(.onSurface)
                        Text("Sign in to sync your data")
                            .font(.caption)
                            .foregroundColor(.onSurface)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Button("Add Account") {
                    context.send(viewAction: .addAccount)
                }
                .foregroundColor(.primary)
            }
        } header: {
            Text("Account")
        }
    }
    
    @ViewBuilder
    private var generalSection: some View {
        Section {
            
            Picker("Apperance", selection: context.viewState.bindings.binding(for: \.appearance)) {
                ForEach(AppAppearance.allCases, id: \.self) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
            
            Toggle("Open Event from Widget", isOn: context.viewState.bindings.binding(for: \.openEventFromWidget))
            
            SettingsRow(
                icon: "bell.fill",
                iconColor: .red,
                title: "Notifications",
                subtitle: "Manage notification preferences"
            ) {
                context.send(viewAction: .notifications)
            }
            
            SettingsRow(
                icon: "globe",
                iconColor: .blue,
                title: "Language & Region",
                subtitle: "English"
            ) {
                context.send(viewAction: .language)
            }
            
            SettingsRow(
                icon: "bookmark",
                iconColor: .primary,
                title: "Bookmarked Programmes",
                subtitle: "You have \(context.viewState.bindings.bookmarkedProgrammes.count) bookmarked programmes"
            ) {
                if context.viewState.bindings.bookmarkedProgrammes.count > 0 {
                    context.send(viewAction: .bookmarkedProgrammes)
                }
            }
            
        } header: {
            Text("General")
        }
    }
    
    @ViewBuilder
    private var supportSection: some View {
        Section {
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconColor: .green,
                title: "Help & Support",
                subtitle: "FAQs and contact information"
            ) {
                context.send(viewAction: .help)
            }
            
            SettingsRow(
                icon: "star.fill",
                iconColor: .yellow,
                title: "Rate the App",
                subtitle: "Share your feedback on the App Store"
            ) {
                context.send(viewAction: .rateApp)
            }
            
            SettingsRow(
                icon: "envelope.fill",
                iconColor: .blue,
                title: "Send Feedback",
                subtitle: "Report bugs or suggest features"
            ) {
                context.send(viewAction: .sendFeedback)
            }
            
        } header: {
            Text("Support")
        }
    }
    
    @ViewBuilder
    private var advancedSection: some View {
        Section {
            SettingsRow(
                icon: "gearshape.2.fill",
                iconColor: .gray,
                title: "Advanced Settings",
                subtitle: "Cache, network, and developer options"
            ) {
                context.send(viewAction: .advancedSettings)
            }
            
            SettingsRow(
                icon: "info.circle.fill",
                iconColor: .blue,
                title: "About",
                subtitle: "Version, licenses, and app information"
            ) {
                context.send(viewAction: .about)
            }
            
        } header: {
            Text("Advanced")
        } footer: {
            VStack(alignment: .center, spacing: 8) {
                Text("Version \(Config.appVersion) (Build \(Config.bundleVersion))")
                    .font(.caption)
                    .foregroundColor(.onBackground)
                
                Text("© 2025 Tumble Studios")
                    .font(.caption2)
                    .foregroundColor(.onBackground)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(iconColor)
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.onSurface)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.onSurface.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.onSurface)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
