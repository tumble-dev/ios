//
//  OpenDetailsFromWidgetPreference.swift
//  App
//
//  Created by Timur Ramazanov on 24.10.2024.
//

import Foundation

class OpenEventFromWidgetPreference: PreferenceStorable {
    typealias ValueType = Bool
    var key: SharedPreferenceKey = .openEventFromWidget
    
    func get() -> Bool {
        return UserDefaults.standard.object(forKey: key.rawValue) as? Bool ?? true
    }
    
    func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
