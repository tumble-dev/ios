//
//  FirstOpenPreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class FirstOpenPreference: PreferenceStorable {
    typealias ValueType = Bool
    var key: SharedPreferenceKey = .firstOpen
    
    func get() -> Bool {
        return UserDefaults.standard.object(forKey: key.rawValue) as? Bool ?? true
    }
    
    func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

