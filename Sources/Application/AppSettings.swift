//
//  AppSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation
import Combine

final class AppSettings: ObservableObject {
    private enum UserDefaultsKeys: String {
        // Internal
        case lastVersionLaunched
        case activeSchool // "hkr", "mau"
        case activeUserId
        case onboarded
        case bookmarkViewType
        case hasRunNotificationPermissionsOnboarding
        
        // Notification Settings - Messaging
        case notificationsEnabled
        case inAppMessagingEnabled
        case notificationOffset
        
        // Settings - General
        case appearance
        case language
        
        // Settings - Behavior
        case openEventFromWidget
        
        // Bookmark Settings - Programmes
        case bookmarkedProgrammes
        
        // Advanced Settings - Performance & Data
        case wifiOnlyMode
        case backgroundRefreshEnabled
        case syncFrequency
        
        // Advanced Settings - Privacy & Security
        case analyticsEnabled
        
        // Advanced Settings - Network & Connectivity
        case connectionTimeout
        case retryAttempts
        
        // Advanced Settings - Storage & Backup
        case storageOptimizationEnabled
        
        // Advanced Settings - Development
        case debugModeEnabled
        case loggingLevel
        case performanceMonitoringEnabled
        case betaFeaturesEnabled
    }
    
    private static var suiteName: String = Config.appGroupIdentifier
    
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)
    
    static func resetAllSettings() {
        store.removePersistentDomain(forName: suiteName)
    }
    
    static func configureWithSuiteName(_ name: String) {
        suiteName = name
        guard let userDefaults = UserDefaults(suiteName: name) else {
            fatalError("failed to load shared UserDefaults")
        }
        store = userDefaults
    }
    
    // MARK: - Existing Settings
    
    @UserPreference(key: UserDefaultsKeys.notificationsEnabled, defaultValue: true, storageType: .userDefaults(store))
    var notificationsEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.inAppMessagingEnabled, defaultValue: true, storageType: .userDefaults(store))
    var inAppMessagingEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.lastVersionLaunched, storageType: .userDefaults(store))
    var lastVersionLaunched: String?
    
    @UserPreference(key: UserDefaultsKeys.appearance, defaultValue: .system, storageType: .userDefaults(store))
    var appearance: AppAppearance
    
    @UserPreference(key: UserDefaultsKeys.activeSchool, storageType: .userDefaults(store))
    var activeSchool: String?
    
    @UserPreference(key: UserDefaultsKeys.activeUserId, storageType: .userDefaults(store))
    var activeUserId: String?
    
    @UserPreference(key: UserDefaultsKeys.language, defaultValue: "en", storageType: .userDefaults(store))
    var language: String
    
    @UserPreference(key: UserDefaultsKeys.notificationOffset, defaultValue: .hour, storageType: .userDefaults(store))
    var notificationOffset: NotificationOffset
    
    @UserPreference(key: UserDefaultsKeys.onboarded, defaultValue: false, storageType: .userDefaults(store))
    var onboarded: Bool
    
    @UserPreference(key: UserDefaultsKeys.bookmarkedProgrammes, defaultValue: [:], storageType: .userDefaults(store))
    var bookmarkedProgrammes: [String : Bool]
    
    @UserPreference(key: UserDefaultsKeys.openEventFromWidget, defaultValue: false, storageType: .userDefaults(store))
    var openEventFromWidget: Bool
    
    @UserPreference(key: UserDefaultsKeys.bookmarkViewType, defaultValue: 0, storageType: .userDefaults(store))
    var bookmarkViewType: Int
    
    @UserPreference(key: UserDefaultsKeys.hasRunNotificationPermissionsOnboarding, defaultValue: false, storageType: .userDefaults(store))
    var hasRunNotificationPermissionsOnboarding: Bool
    
    // MARK: - Advanced Settings - Performance & Data
    
    @UserPreference(key: UserDefaultsKeys.wifiOnlyMode, defaultValue: false, storageType: .userDefaults(store))
    var wifiOnlyMode: Bool
    
    @UserPreference(key: UserDefaultsKeys.backgroundRefreshEnabled, defaultValue: true, storageType: .userDefaults(store))
    var backgroundRefreshEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.syncFrequency, defaultValue: .daily, storageType: .userDefaults(store))
    var syncFrequency: SyncFrequency
    
    // MARK: - Advanced Settings - Privacy & Security
    
    @UserPreference(key: UserDefaultsKeys.analyticsEnabled, defaultValue: true, storageType: .userDefaults(store))
    var analyticsEnabled: Bool
    
    // MARK: - Advanced Settings - Network & Connectivity
    
    @UserPreference(key: UserDefaultsKeys.connectionTimeout, defaultValue: 30.0, storageType: .userDefaults(store))
    var connectionTimeout: Double
    
    @UserPreference(key: UserDefaultsKeys.retryAttempts, defaultValue: 3, storageType: .userDefaults(store))
    var retryAttempts: Int
    
    // MARK: - Advanced Settings - Storage & Backup
    
    @UserPreference(key: UserDefaultsKeys.storageOptimizationEnabled, defaultValue: true, storageType: .userDefaults(store))
    var storageOptimizationEnabled: Bool
    
    // MARK: - Advanced Settings - Development
    
    @UserPreference(key: UserDefaultsKeys.debugModeEnabled, defaultValue: false, storageType: .userDefaults(store))
    var debugModeEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.loggingLevel, defaultValue: .error, storageType: .userDefaults(store))
    var loggingLevel: LoggingLevel
    
    @UserPreference(key: UserDefaultsKeys.performanceMonitoringEnabled, defaultValue: false, storageType: .userDefaults(store))
    var performanceMonitoringEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.betaFeaturesEnabled, defaultValue: false, storageType: .userDefaults(store))
    var betaFeaturesEnabled: Bool
}


// MARK: - Protocol Extensions for Settings


// MARK: - AdvancedSettingsProtocol Extension

extension AppSettings: AdvancedSettingsProtocol {

    var cacheSize: String {
        // Calculate actual cache size
        let urlCacheSize = URLCache.shared.currentDiskUsage + URLCache.shared.currentMemoryUsage
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(urlCacheSize))
    }
    
    func resetAdvancedSettings() {
        // Performance & Data
        self.wifiOnlyMode = false
        self.backgroundRefreshEnabled = true
        self.syncFrequency = .daily
        
        // Privacy & Security
        self.analyticsEnabled = true
        
        // Network & Connectivity
        self.connectionTimeout = 30.0
        self.retryAttempts = 3
        
        // Storage & Backup
        self.storageOptimizationEnabled = true
        
        // Development
        self.debugModeEnabled = false
        self.loggingLevel = .error
        self.performanceMonitoringEnabled = false
        self.betaFeaturesEnabled = false
    }
}

// MARK: - NotificationsSettingsProtocol Extension

extension AppSettings: NotificationsSettingsProtocol {
    func resetNotificationsSettings() {
        self.notificationOffset = .hour
        self.inAppMessagingEnabled = true
        self.notificationsEnabled = true
    }
}

// MARK: - SettingsProtocol Extension

extension AppSettings: SettingsProtocol { }
