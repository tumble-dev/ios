//
//  AppearancePreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class AppearancePreference: PreferenceStorable {
    typealias ValueType = String
    var key: SharedPreferenceKey = .appearance
    
    func get() -> String {
        return UserDefaults.standard.string(forKey: key.rawValue) ?? AppearanceType.system.rawValue
    }
    
    func set(_ value: String) {
        AppLogger.shared.debug("Setting appearance to \(value)")
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
