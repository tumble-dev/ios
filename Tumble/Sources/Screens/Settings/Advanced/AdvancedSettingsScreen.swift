//
//  AdvancedSettingsScreen.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import SwiftUI

struct AdvancedSettingsScreen: View {
    @ObservedObject var context: AdvancedSettingsScreenViewModel.Context
    @State private var showingClearCacheAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        Form {
            performanceDataSection
            privacySecuritySection
            networkConnectivitySection
            storageBackupSection
            developmentSection
            resetSection
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                context.send(viewAction: .clearCache)
            }
        } message: {
            Text("This will clear all cached data. The app may need to re-download content.")
        }
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
    private var performanceDataSection: some View {
        Section {
            // Cache Management
            HStack {
                Text("Cache Size")
                Spacer()
                Text(context.viewState.bindings.cacheSize)
                    .foregroundColor(.onSurface)
            }
            
            Button("Clear Cache") {
                showingClearCacheAlert = true
            }
            .foregroundColor(.red)
            
            // Data Usage Controls
            Toggle("WiFi Only Mode", isOn: context.viewState.bindings.binding(for: \.wifiOnlyMode))
            
            Toggle("Background App Refresh", isOn: context.viewState.bindings.binding(for: \.backgroundRefreshEnabled))
            
            Picker("Sync Frequency", selection: context.viewState.bindings.binding(for: \.syncFrequency)) {
                ForEach(SyncFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            
        } header: {
            Text("Performance & Data")
        } footer: {
            Text("Manage app performance and data usage settings.")
        }
    }
    
    @ViewBuilder
    private var privacySecuritySection: some View {
        Section {
            Toggle("Analytics & Crash Reports", isOn: context.viewState.bindings.binding(for: \.analyticsEnabled))
            
        } header: {
            Text("Privacy & Security")
        } footer: {
            Text("Control privacy and security features to protect your data.")
        }
    }
    
    @ViewBuilder
    private var networkConnectivitySection: some View {
        Section {
            HStack {
                Text("Connection Timeout")
                Spacer()
                Text("\(Int(context.viewState.bindings.connectionTimeout))s")
                    .foregroundColor(.onSurface)
            }
            
            Slider(
                value: context.viewState.bindings.binding(for: \.connectionTimeout),
                in: 5...60,
                step: 5
            )
            
            Stepper("Retry Attempts: \(context.viewState.bindings.retryAttempts)",
                   value: context.viewState.bindings.binding(for: \.retryAttempts),
                   in: 1...10)
            
        } header: {
            Text("Network & Connectivity")
        } footer: {
            Text("Configure network settings and connection parameters.")
        }
    }
    
    @ViewBuilder
    private var storageBackupSection: some View {
        Section {
            
            Toggle("Storage Optimization", isOn: context.viewState.bindings.binding(for: \.storageOptimizationEnabled))
            
            Button("Export Data") {
                context.send(viewAction: .exportData)
            }
            
            Button("Import Data") {
                context.send(viewAction: .importData)
            }
            
        } header: {
            Text("Storage & Backup")
        } footer: {
            Text("Manage data storage, backup, and export options.")
        }
    }
    
    @ViewBuilder
    private var developmentSection: some View {
        Section {
            Toggle("Debug Mode", isOn: context.viewState.bindings.binding(for: \.debugModeEnabled))
            
            if context.viewState.bindings.debugModeEnabled {
                Picker("Logging Level", selection: context.viewState.bindings.binding(for: \.loggingLevel)) {
                    ForEach(LoggingLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                
                Toggle("Performance Monitoring", isOn: context.viewState.bindings.binding(for: \.performanceMonitoringEnabled))
            }
            
            Toggle("Beta Features", isOn: context.viewState.bindings.binding(for: \.betaFeaturesEnabled))
            
        } header: {
            Text("Development")
        } footer: {
            Text("Advanced settings for developers and beta testing.")
        }
    }
    
    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button("Reset All Advanced Settings") {
                showingResetAlert = true
            }
            .foregroundColor(.red)
            
        } footer: {
            Text("Reset all advanced settings to their default values.")
        }
    }
}
