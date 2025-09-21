//
//  PreferenceKey.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-27.
//

import Foundation

enum SharedPreferenceKey: String {
    case authSchool = "auth_school"
    case appearance = "appearance"
    case userOnboarded = "user_onboarded"
    case locale = "locale"
    case notificationOffset = "notification_offset"
    case viewType = "view_type"
    case networkSettings = "network_settings"
    case lastUpdated = "last_updated"
    case firstOpen = "first_open"
    case openEventFromWidget = "open_event_from_widget"
    case currentUser = "current_user"
}
