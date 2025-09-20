//
//  Config.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-16.
//

import Foundation

enum Config {
    static let baseBundleIdentifier             = Bundle.main.info(for: "BASE_BUNDLE_IDENTIFIER")
    static let keychainAccessGroupIdentifier    = Bundle.main.info(for: "KEYCHAIN_ACCESS_GROUP_IDENTIFIER")
    static let apiUrl                           = Bundle.main.info(for: "API_URL")
    static let apiKey                           = Bundle.main.info(for: "API_KEY")
    static let appVersion                       = Bundle.main.info(for: "APP_VERSION")
    static let appGroupIdentifier               = Bundle.main.info(for: "APP_GROUP_IDENTIFIER")
    static let bundleShortVersionString         = Bundle.main.info(for: "CFBundleShortVersionString")
    static let bundleDisplayName                = Bundle.main.info(for: "CFBundleDisplayName")
    static let bundleVersion                    = Bundle.main.info(for: kCFBundleVersionKey as String)
}

private extension Bundle {
    func info(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String else {
            fatalError("Missing key \(key) in Info.plist or xcconfig")
        }
        return value
    }
}
