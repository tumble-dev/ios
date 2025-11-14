import Combine
import SwiftUI

struct SettingsScreen: View {
    @ObservedObject var context: SettingsScreenViewModel.Context
    @State private var showingRemoveAccountAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                accountSection
                generalSection
                supportSection
                advancedSection
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingL)
        }
        .background(Color.tumbleBackground)
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
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                context.send(viewAction: .removeAccount)
            }
        } message: {
            Text("This will sign you out of Kronox. Any notifications you had set for bookings or exams will be cleared.")
        }
    }
    
    @ViewBuilder
    private var accountSection: some View {
        SettingsCard(title: "Account") {
            VStack(spacing: 16) {
                switch context.viewState.authState {
                case .loading:
                    HStack {
                        Text("Loading your accounts ...")
                        Spacer()
                        ProgressView()
                    }
                case .disconnected:
                    if context.viewState.bindings.allUsers.count == 0 {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclam")
                                .foregroundColor(.tumbleOnSurface)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No accounts added")
                                    .font(.headline)
                                Text("Sign in to sync your data")
                                    .font(.caption)
                                    .foregroundColor(.tumbleOnSurface)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        SettingsButton(title: "Add Account", style: .primary) {
                            context.send(viewAction: .addAccount)
                        }
                    } else {
                        HStack {
                            Text("No connection")
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                        }
                    }
                case .error:
                    HStack {
                        Text("No connection")
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    }
                case .connected(let user):
                    HStack {
                        UserAvatar(username: user.name)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.tumbleOnSurface)
                            Text(user.username)
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface)
                            Text(user.school.uppercased())
                                .font(.caption2)
                                .foregroundColor(.tumbleOnSurface.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    
                    if context.viewState.bindings.allUsers.count > 1 {
                        Divider()
                        
                        HStack(spacing: 16) {
                            Text("Active User")
                                .font(.body)
                            Spacer()
                            Picker("User", selection: context.viewState.bindings.activeUsernameBinding()) {
                                ForEach(context.viewState.bindings.allUsers, id: \.username) { user in
                                    Text(user.name).tag(Optional(user.username))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .font(.subheadline)
                            .fixedSize()
                        }
                        .padding(.vertical, 2)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        SettingsButton(title: "Add Account", style: .primary) {
                            context.send(viewAction: .addAccount)
                        }
                        Divider()
                        
                        SettingsButton(title: "Log Out", style: .destructive) {
                            showingRemoveAccountAlert = true
                        }
                    }
                }
            }
            .padding(.vertical, .spacingM)
        }
    }
    
    @ViewBuilder
    private var generalSection: some View {
        SettingsCard(title: "General") {
            VStack(spacing: 0) {
                HStack {
                    Text("Appearance")
                    Spacer()
                    Picker("Appearance", selection: context.viewState.bindings.binding(for: \.appearance)) {
                        ForEach(AppAppearance.allCases, id: \.self) { appearance in
                            Text(appearance.displayName).tag(appearance)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                HStack {
                    Text("Open Event from Widget")
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.openEventFromWidget))
                        .tint(.tumblePrimary)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notifications",
                    subtitle: "Manage notification preferences"
                ) {
                    context.send(viewAction: .notifications)
                }
                
                Divider()
                
                SettingsRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Language & Region",
                    subtitle: "English"
                ) {
                    context.send(viewAction: .language)
                }
                
                Divider()
                
                SettingsRow(
                    icon: "bookmark",
                    iconColor: .tumblePrimary,
                    title: "Bookmarked Programmes",
                    subtitle: "You have \(context.viewState.bindings.bookmarkedProgrammes.count) bookmarked programmes"
                ) {
                    if context.viewState.bindings.bookmarkedProgrammes.count > 0 {
                        context.send(viewAction: .bookmarkedProgrammes)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var supportSection: some View {
        SettingsCard(title: "Support") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .green,
                    title: "Help & Support",
                    subtitle: "FAQs and contact information"
                ) {
                    context.send(viewAction: .help)
                }
                
                Divider()
                
                SettingsRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Rate the App",
                    subtitle: "Share your feedback on the App Store"
                ) {
                    context.send(viewAction: .rateApp)
                }
                
                Divider()
                
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "Send Feedback",
                    subtitle: "Report bugs or suggest features"
                ) {
                    context.send(viewAction: .sendFeedback)
                }
            }
        }
    }
    
    @ViewBuilder
    private var advancedSection: some View {
        SettingsCard(title: "Advanced") {
            VStack(spacing: 0) {
                SyncStatusIndicator()
                
                Divider()
                
                SettingsRow(
                    icon: "gearshape.2.fill",
                    iconColor: .gray,
                    title: "Advanced Settings",
                    subtitle: "Cache, network, and developer options"
                ) {
                    context.send(viewAction: .advancedSettings)
                }
                
                Divider()
                
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .blue,
                    title: "About",
                    subtitle: "Version, licenses, and app information"
                ) {
                    context.send(viewAction: .about)
                }
            }
        }
        
        // Footer
        VStack(alignment: .center, spacing: 8) {
            Text("Version \(Config.appVersion) (Build \(Config.bundleVersion))")
                .font(.caption)
                .foregroundColor(.tumbleOnBackground)
            
            Text("© 2025 Tumble Studios")
                .font(.caption2)
                .foregroundColor(.tumbleOnBackground)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
}

// MARK: - Helper Components

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.tumbleOnBackground)
                .padding(.leading, 4)
            
            VStack {
                content
            }
            .padding(.horizontal, .spacingM)
            .cardStyle()
        }
    }
}

struct SettingsButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case destructive
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(style == .destructive ? .red : .tumblePrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Keep your existing SettingsRow component
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
                        .foregroundColor(.tumbleOnSurface)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.tumbleOnSurface)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tumbleOnSurface)
            }
            .padding(.vertical, .spacingM)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
