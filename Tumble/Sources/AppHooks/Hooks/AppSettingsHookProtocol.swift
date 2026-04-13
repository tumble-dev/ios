//
//  AppSettingsHookProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation

protocol AppSettingsHookProtocol {
    func configure(_ appSettings: AppSettings) -> AppSettings
}

struct DefaultAppSettingsHook: AppSettingsHookProtocol {
    func configure(_ appSettings: AppSettings) -> AppSettings { appSettings }
}
