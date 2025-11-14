//
//  SyncStatusIndicator.swift
//  Tumble
//
//  Created by Assistant on 2025-11-14.
//

import Combine
import SwiftUI

// MARK: - Local Sync Status (mirroring EventSyncStatus from EventSyncService)

enum SyncStatus {
    case idle
    case syncing
    case success
    case failed(String)
    
    var displayText: String {
        switch self {
        case .idle: return "Ready to sync"
        case .syncing: return "Syncing events..."
        case .success: return "Up to date"
        case .failed: return "Sync failed"
        }
    }
}

// MARK: - Sync Status Indicator

struct SyncStatusIndicator: View {
    @ObservedObject private var eventSyncManager: EventSyncManager
    @State private var showingDetails = false
    @State private var isManualSyncing = false
    @State private var currentStatus: SyncStatus = .idle
    @State private var lastManualSyncTime: Date?
    @State private var syncCooldownTimer: Timer?
    @State private var remainingCooldownSeconds: Int = 0
    
    // Rate limiting configuration
    private let syncCooldownDuration: TimeInterval = 30 // 30 seconds between manual syncs
    
    init() {
        eventSyncManager = ServiceLocator.shared.eventSyncService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main sync status row
            HStack(spacing: 12) {
                // Status icon with animation
                statusIcon
                    .frame(width: 28, height: 28)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Event Sync")
                        .font(.body)
                        .foregroundColor(.tumbleOnSurface)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.tumbleOnSurface.opacity(0.7))
                }
                
                Spacer()
                
                // Manual sync button (when not auto-syncing)
                if !isSyncing {
                    Button(action: performManualSync) {
                        HStack(spacing: 4) {
                            if remainingCooldownSeconds > 0 {
                                Text("\(remainingCooldownSeconds)")
                                    .font(.caption2)
                                    .foregroundColor(.tumbleSecondary)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .rotationEffect(.degrees(isManualSyncing ? 360 : 0))
                                    .animation(
                                        isManualSyncing ?
                                            Animation.linear(duration: 1).repeatForever(autoreverses: false) :
                                            .default,
                                        value: isManualSyncing
                                    )
                            }
                        }
                        .foregroundColor(canPerformManualSync ? .tumblePrimary : .tumbleSecondary)
                    }
                    .disabled(!canPerformManualSync || isManualSyncing)
                }
                
                // Details chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tumbleOnSurface.opacity(0.5))
            }
            .padding(.vertical, .spacingM)
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetails.toggle()
            }
            
            // Expandable details section
            if showingDetails {
                Divider()
                
                VStack(spacing: 8) {
                    // Last sync time and cooldown info
                    if let lastSync = eventSyncManager.lastSyncDate {
                        HStack {
                            Text("Last sync:")
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                            Spacer()
                            Text(formatSyncDate(lastSync))
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.9))
                        }
                    }
                    
                    // Manual sync cooldown info
                    if remainingCooldownSeconds > 0 {
                        HStack {
                            Text("Manual sync available in:")
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                            Spacer()
                            Text("\(remainingCooldownSeconds)s")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Sync frequency
                    if let settings = ServiceLocator.shared.settings {
                        HStack {
                            Text("Frequency:")
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                            Spacer()
                            Text(settings.syncFrequency.displayName)
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.9))
                        }
                    }
                    
                    // Next sync (if scheduled)
                    if let nextSync = getNextSyncTime() {
                        HStack {
                            Text("Next sync:")
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                            Spacer()
                            Text(nextSync, style: .relative)
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.9))
                        }
                    }
                    
                    // Network status
                    HStack {
                        Text("Network:")
                            .font(.caption)
                            .foregroundColor(.tumbleOnSurface.opacity(0.7))
                        Spacer()
                        HStack(spacing: 4) {
                            let isOnline = eventSyncManager.isOnline
                            Circle()
                                .fill(isOnline ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(isOnline ? "Connected" : "Offline")
                                .font(.caption)
                                .foregroundColor(.tumbleOnSurface.opacity(0.9))
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, .spacingM)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingDetails)
        .onReceive(eventSyncManager.syncStatus) { status in
            // Convert from EventSyncStatus to our local SyncStatus
            switch status {
            case .idle:
                currentStatus = .idle
            case .syncing:
                currentStatus = .syncing
            case .success:
                currentStatus = .success
            case .failed(let error):
                currentStatus = .failed(error.localizedDescription)
            }
        }
        .onAppear {
            checkExistingCooldown()
        }
        .onDisappear {
            syncCooldownTimer?.invalidate()
            syncCooldownTimer = nil
        }
    }
    
    // MARK: - Status Properties
    
    private var isSyncing: Bool {
        if case .syncing = currentStatus {
            return true
        }
        return false
    }
    
    private var canPerformManualSync: Bool {
        return !isManualSyncing && !isSyncing && remainingCooldownSeconds == 0
    }
    
    private var statusIcon: some View {
        Group {
            switch currentStatus {
            case .idle:
                Image(systemName: "cloud")
                    .foregroundColor(.blue)
            case .syncing:
                Image(systemName: "cloud.fill")
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isSyncing ? 360 : 0))
                    .animation(
                        isSyncing ?
                            Animation.linear(duration: 2).repeatForever(autoreverses: false) :
                            .default,
                        value: isSyncing
                    )
            case .success:
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "icloud.slash")
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 16, weight: .medium))
    }
    
    private var statusColor: Color {
        switch currentStatus {
        case .idle: return .blue
        case .syncing: return .blue
        case .success: return .green
        case .failed: return .red
        }
    }
    
    private var statusText: String {
        switch currentStatus {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing events..."
        case .success:
            if let lastSync = eventSyncManager.lastSyncDate {
                return "Last sync: \(formatSyncDate(lastSync))"
            } else {
                return "Up to date"
            }
        case .failed:
            return "Sync failed"
        }
    }
    
    // MARK: - Actions
    
    private func performManualSync() {
        guard canPerformManualSync else {
            AppLogger.shared.info("Manual sync blocked: cooldown active or already syncing")
            return
        }
        
        isManualSyncing = true
        lastManualSyncTime = Date()
        startCooldownTimer()
        
        Task { @MainActor in
            do {
                _ = try await eventSyncManager.performManualSync()
                AppLogger.shared.info("Manual sync completed successfully")
            } catch {
                AppLogger.shared.error("Manual sync failed: \(error)")
            }
            isManualSyncing = false
        }
    }
    
    private func startCooldownTimer() {
        remainingCooldownSeconds = Int(syncCooldownDuration)
        
        syncCooldownTimer?.invalidate()
        syncCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.remainingCooldownSeconds > 0 {
                self.remainingCooldownSeconds -= 1
            } else {
                timer.invalidate()
                self.syncCooldownTimer = nil
            }
        }
    }
    
    private func checkExistingCooldown() {
        guard let lastSyncTime = lastManualSyncTime else { return }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
        let remainingCooldown = max(0, syncCooldownDuration - timeSinceLastSync)
        
        if remainingCooldown > 0 {
            remainingCooldownSeconds = Int(remainingCooldown)
            startCooldownTimer()
        }
    }
    
    private func getNextSyncTime() -> Date? {
        guard let settings = ServiceLocator.shared.settings else { return nil }
        
        guard settings.backgroundRefreshEnabled,
              settings.syncFrequency != .manual,
              let lastSync = eventSyncManager.lastSyncDate
        else {
            return nil
        }
        
        let interval: TimeInterval
        switch settings.syncFrequency {
        case .manual: return nil
        case .hourly: interval = 3600
        case .daily: interval = 86400
        case .weekly: interval = 604800
        }
        
        return lastSync.addingTimeInterval(interval)
    }
    
    private func formatSyncDate(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Previews

struct SyncStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SettingsCard(title: "Sync Status") {
                SyncStatusIndicator()
            }
        }
        .padding()
        .background(Color.tumbleBackground)
    }
}
