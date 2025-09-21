//
//  AdvancedSettingsScreenModels.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Foundation
import SwiftUI

struct AdvancedSettingsScreenViewState: BindableState {
    var bindings: AdvancedSettingsScreenViewStateBindings
}

@dynamicMemberLookup
struct AdvancedSettingsScreenViewStateBindings {
    private let advancedSettings: AdvancedSettingsProtocol

    init(advancedSettings: AdvancedSettingsProtocol) {
        self.advancedSettings = advancedSettings
    }

    // For get-only properties (like cacheSize)
    subscript<Setting>(dynamicMember keyPath: KeyPath<AdvancedSettingsProtocol, Setting>) -> Setting {
        advancedSettings[keyPath: keyPath]
    }
    
    // For get-set properties that return the value directly
    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<AdvancedSettingsProtocol, Setting>) -> Setting {
        get { advancedSettings[keyPath: keyPath] }
        set { advancedSettings[keyPath: keyPath] = newValue }
    }
    
    // For get-set properties that return Bindings (using a different method name to avoid conflicts)
    func binding<Setting>(for keyPath: ReferenceWritableKeyPath<AdvancedSettingsProtocol, Setting>) -> Binding<Setting> {
        Binding(
            get: { self.advancedSettings[keyPath: keyPath] },
            set: { self.advancedSettings[keyPath: keyPath] = $0 }
        )
    }
}

enum AdvancedSettingsScreenViewAction {
    case clearCache
    case exportData
    case importData
    case resetAllSettings
}

// MARK: - Enums for Settings

enum SyncFrequency: Int, Codable, CaseIterable {
    case manual = 0
    case hourly = 1
    case daily = 2
    case weekly = 3
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

enum AutoDeletePeriod: Int, Codable, CaseIterable {
    case never = 0
    case thirtyDays = 1
    case sixtyDays = 2
    case ninetyDays = 3
    case oneYear = 4
    
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .thirtyDays: return "30 Days"
        case .sixtyDays: return "60 Days"
        case .ninetyDays: return "90 Days"
        case .oneYear: return "1 Year"
        }
    }
}

enum BackupFrequency: Int, Codable, CaseIterable {
    case daily = 0
    case weekly = 1
    case monthly = 2
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

enum LoggingLevel: Int, Codable, CaseIterable {
    case error = 0
    case warning = 1
    case info = 2
    case debug = 3
    case verbose = 4
    
    var displayName: String {
        switch self {
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Info"
        case .debug: return "Debug"
        case .verbose: return "Verbose"
        }
    }
}

// MARK: - Protocol Extension

protocol AdvancedSettingsProtocol: AnyObject {
    
    func resetAdvancedSettings() -> Void
    
    // Performance & Data
    var cacheSize: String { get }
    var wifiOnlyMode: Bool { get set }
    var backgroundRefreshEnabled: Bool { get set }
    var syncFrequency: SyncFrequency { get set }
    
    // Privacy & Security
    var analyticsEnabled: Bool { get set }
    
    // Network & Connectivity
    var connectionTimeout: Double { get set }
    var retryAttempts: Int { get set }
    
    // Storage & Backup
    var storageOptimizationEnabled: Bool { get set }
    
    // Development
    var debugModeEnabled: Bool { get set }
    var loggingLevel: LoggingLevel { get set }
    var performanceMonitoringEnabled: Bool { get set }
    var betaFeaturesEnabled: Bool { get set }
}
