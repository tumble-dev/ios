//
//  LastUpdatedPreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class LastUpdatedPreference: PreferenceStorable {
    typealias ValueType = Date
    var key: SharedPreferenceKey = .lastUpdated
    
    func get() -> Date {
        return UserDefaults.standard.object(forKey: key.rawValue) as? Date ?? Date(timeIntervalSince1970: 0)
    }
    
    func set(_ value: Date) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

