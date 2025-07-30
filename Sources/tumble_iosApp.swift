//
//  tumble_iosApp.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/16/22.
//

import SwiftUI
import MijickPopupView

@main
struct tumble_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        /// Cache the environment variable in app storage (user defaults).
        if let networkSettings = ProcessInfo.processInfo.environment["NETWORK_SETTINGS"] {
            UserDefaults.standard.set(networkSettings, forKey: SharedPreferenceKey.networkSettings.rawValue)
            UserDefaults.standard.synchronize()
        }
        /// Initialize dependency providers
        _ = Dependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            Root().implementPopupView()
        }
    }
}
