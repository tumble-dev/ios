//
//  LanguagePreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class LanguagePreference: PreferenceStorable {
    typealias ValueType = String
    var key: SharedPreferenceKey = .locale
    
    func get() -> String {
        return UserDefaults.standard.string(forKey: key.rawValue) ?? "en"
    }
    
    func set(_ value: String) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

