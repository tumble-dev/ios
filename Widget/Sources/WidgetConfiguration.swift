//
//  WidgetConfiguration.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import Foundation

struct TumbleWidgetConfiguration {
    /// App Group identifier for sharing data between main app and widget
    /// This should match the App Group created in Apple Developer Portal and Config
    static let appGroupIdentifier = Config.appGroupIdentifier
    
    /// Shared UserDefaults suite for app-widget communication
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Keys for shared preferences
    enum SharedKeys {
        static let lastEventUpdate = "widget_last_event_update"
        static let cachedEvents = "widget_cached_events"
        static let userPreferences = "widget_user_preferences"
    }
}
