//
//  NetworkSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-29.
//

import Foundation

/// Dynamic network settings based on the $(NETWORK_SETTINGS)
/// property list key that is toggled by changing build schemes.
struct NetworkSettings {
    static let shared = NetworkSettings()
    
    enum Environments {
        // Production URL
        static let production = NetworkSettings(
            port: 443, scheme: "https", tumbleUrl: "app.tumbleforkronox.com"
        )

        // Debug URL
        static let development = NetworkSettings(
            port: 7036, scheme: "http", tumbleUrl: "localhost"
        )
    }

    let port: Int
    let scheme: String
    let tumbleUrl: String
}
