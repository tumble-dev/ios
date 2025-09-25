//
//  AnalyticsService.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import FirebaseAnalytics
import Foundation
import Combine
import FirebaseCrashlytics

protocol AnalyticsServiceProtocol {
    func logEvent(_ event: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserId(_ userId: String?)
}

final class AnalyticsService: AnalyticsServiceProtocol {
    private let appSettings: AppSettings
    private var cancellables = Set<AnyCancellable>()
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        
        updateFirebaseCollectionState(appSettings.analyticsEnabled)
        
        appSettings.$analyticsEnabled
            .sink { [weak self] enabled in
                self?.updateFirebaseCollectionState(enabled)
            }
            .store(in: &cancellables)
    }
    
    func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        guard appSettings.analyticsEnabled else {
            AppLogger.shared.info("Analytics disabled - skipping event: \(event)")
            return
        }
        
        Analytics.logEvent(event, parameters: parameters)
        AppLogger.shared.info("Analytics event logged: \(event)")
    }
    
    private func updateFirebaseCollectionState(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
        
        AppLogger.shared.info("Firebase Analytics collection set to: \(enabled)")
    }
    func setUserProperty(_ value: String?, forName name: String) {
        guard appSettings.analyticsEnabled else {
            AppLogger.shared.info("Analytics disabled - skipping user property: \(name)")
            return
        }
        
        Analytics.setUserProperty(value, forName: name)
    }
    
    func setUserId(_ userId: String?) {
        guard appSettings.analyticsEnabled else {
            AppLogger.shared.info("Analytics disabled - skipping user ID")
            return
        }
        
        Analytics.setUserID(userId)
    }
}

// MARK: - Convenience methods

extension AnalyticsService {
    func logSettingChanged(_ settingName: String, oldValue: String, newValue: String) {
        logEvent("setting_changed", parameters: [
            "setting_name": settingName,
            "old_value": oldValue,
            "new_value": newValue
        ])
    }
    
    func logCacheCleared(sizeInMB: String) {
        logEvent("cache_cleared", parameters: [
            "cache_size": sizeInMB
        ])
    }
    
    func logAdvancedSettingsAccessed() {
        logEvent("advanced_settings_accessed", parameters: nil)
    }
    
    func logDataExport() {
        logEvent("data_exported", parameters: nil)
    }
    
    func logDataImport() {
        logEvent("data_imported", parameters: nil)
    }
    
    func logSettingsReset() {
        logEvent("settings_reset", parameters: [
            "reset_type": "advanced_settings"
        ])
    }
}
