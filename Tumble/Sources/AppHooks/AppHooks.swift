//
//  AppHooks.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

class AppHooks: AppHooksProtocol {
    private(set) var appSettingsHook: AppSettingsHookProtocol = DefaultAppSettingsHook()
    func registerAppSettingsHook(_ hook: AppSettingsHookProtocol) {
        appSettingsHook = hook
    }
}

protocol AppHooksProtocol {
    func setUp()
}

extension AppHooksProtocol {
    func setUp() { }
}

