//
//  CurrentUserPreference.swift
//  App
//
//  Created by Timur Ramazanov on 05.11.2024.
//

import Foundation

class CurrentUserPreference: PreferenceStorable {
    typealias ValueType = String
    var key: SharedPreferenceKey = .currentUser
    
    func get() -> String {
        return UserDefaults.standard.string(forKey: key.rawValue) ?? ""
    }
    
    func set(_ value: String) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
