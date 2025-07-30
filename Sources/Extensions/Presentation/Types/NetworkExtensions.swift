//
//  NetworkExtensions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-29.
//

import Foundation

extension NetworkSettings {
    init() {
        let defaultEnvironment = Bundle.main.object(forInfoDictionaryKey: "DEFAULT_NETWORK_SETTINGS") as? String
        let storedEnvironment = UserDefaults.standard.value(forKey: SharedPreferenceKey.networkSettings.rawValue) as? String
        let resolvedEnvironment = storedEnvironment ?? defaultEnvironment
        switch resolvedEnvironment {
        case "development":
            self = Environments.development
        default:
            self = Environments.production
        }
    }
}
