//
//  AppLogger.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-03.
//

import Foundation
import Logging

/// Basic logger singleton shared globally
enum AppLogger {
    static let shared = Logger(label: Config.baseBundleIdentifier)
}
