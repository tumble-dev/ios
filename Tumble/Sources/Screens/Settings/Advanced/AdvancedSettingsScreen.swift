import SwiftUI

struct AdvancedSettingsScreen: View {
    @ObservedObject var context: AdvancedSettingsScreenViewModel.Context
    @State private var showingClearCacheAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                performanceDataSection
                privacySecuritySection
                networkConnectivitySection
                storageBackupSection
                developmentSection
                resetSection
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingL)
        }
        .background(Color.tumbleBackground)
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                context.send(viewAction: .clearCache)
            }
        } message: {
            Text("This will clear all cached data. The app may need to re-download content.")
        }
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
    private var performanceDataSection: some View {
        SettingsCard(title: "Performance & Data") {
            VStack(spacing: 0) {
                HStack {
                    Text("Cache Size")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Text(context.viewState.bindings.cacheSize)
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                SettingsButton(title: "Clear Cache", style: .destructive) {
                    showingClearCacheAlert = true
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                HStack {
                    Text("WiFi Only Mode")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.wifiOnlyMode))
                        .tint(.tumblePrimary)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                HStack {
                    Text("Background App Refresh")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.backgroundRefreshEnabled))
                        .tint(.tumblePrimary)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                HStack {
                    Text("Sync Frequency")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Picker("Sync Frequency", selection: context.viewState.bindings.binding(for: \.syncFrequency)) {
                        ForEach(SyncFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.vertical, .spacingM)
            }
        }
    }
    
    @ViewBuilder
    private var privacySecuritySection: some View {
        SettingsCard(title: "Privacy & Security") {
            HStack {
                Text("Analytics & Crash Reports")
                    .font(.body)
                    .foregroundColor(.tumbleOnSurface)
                Spacer()
                Toggle("", isOn: context.viewState.bindings.binding(for: \.analyticsEnabled))
                    .tint(.tumblePrimary)
            }
            .padding(.vertical, .spacingM)
        }
    }
    
    @ViewBuilder
    private var networkConnectivitySection: some View {
        SettingsCard(title: "Network & Connectivity") {
            VStack(spacing: 0) {
                HStack {
                    Text("Connection Timeout")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Text("\(Int(context.viewState.bindings.connectionTimeout))s")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                }
                .padding(.vertical, .spacingM)
                
                Slider(
                    value: context.viewState.bindings.binding(for: \.connectionTimeout),
                    in: 5...60,
                    step: 5
                )
                .tint(.tumblePrimary)
                .padding(.bottom, .spacingM)
                
                Divider()
                
                HStack {
                    Stepper("Retry Attempts: \(context.viewState.bindings.retryAttempts)",
                            value: context.viewState.bindings.binding(for: \.retryAttempts),
                            in: 1...10)
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                }
                .padding(.vertical, .spacingM)
            }
        }
    }
    
    @ViewBuilder
    private var storageBackupSection: some View {
        SettingsCard(title: "Storage & Backup") {
            VStack(spacing: 0) {
                HStack {
                    Text("Storage Optimization")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.storageOptimizationEnabled))
                        .tint(.tumblePrimary)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                SettingsButton(title: "Export Data", style: .primary) {
                    context.send(viewAction: .exportData)
                }
                .padding(.vertical, .spacingM)
                
                Divider()
                
                SettingsButton(title: "Import Data", style: .primary) {
                    context.send(viewAction: .importData)
                }
                .padding(.vertical, .spacingM)
            }
        }
    }
    
    @ViewBuilder
    private var developmentSection: some View {
        SettingsCard(title: "Development") {
            VStack(spacing: 0) {
                HStack {
                    Text("Debug Mode")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.debugModeEnabled))
                        .tint(.tumblePrimary)
                }
                .padding(.vertical, .spacingM)
                
                if context.viewState.bindings.debugModeEnabled {
                    Divider()
                    
                    HStack {
                        Text("Logging Level")
                            .font(.body)
                            .foregroundColor(.tumbleOnSurface)
                        Spacer()
                        Picker("Logging Level", selection: context.viewState.bindings.binding(for: \.loggingLevel)) {
                            ForEach(LoggingLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.vertical, .spacingM)
                    
                    Divider()
                    
                    HStack {
                        Text("Performance Monitoring")
                            .font(.body)
                            .foregroundColor(.tumbleOnSurface)
                        Spacer()
                        Toggle("", isOn: context.viewState.bindings.binding(for: \.performanceMonitoringEnabled))
                            .tint(.tumblePrimary)
                    }
                    .padding(.vertical, .spacingM)
                }
                
                Divider()
                
                HStack {
                    Text("Beta Features")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    Spacer()
                    Toggle("", isOn: context.viewState.bindings.binding(for: \.betaFeaturesEnabled))
                        .tint(.tumblePrimary)
                }
                .padding(.vertical, .spacingM)
            }
        }
    }
    
    @ViewBuilder
    private var resetSection: some View {
        SettingsCard(title: "Reset") {
            SettingsButton(title: "Reset All Advanced Settings", style: .destructive) {
                showingResetAlert = true
            }
            .padding(.vertical, .spacingM)
        }
    }
}
