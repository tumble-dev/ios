//
//  NotificationOffsetPreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class NotificationOffsetPreference: PreferenceStorable {
    typealias ValueType = Int
    var key: SharedPreferenceKey = .notificationOffset
    
    func get() -> Int {
        if let value = UserDefaults.standard.object(forKey: key.rawValue) as? Int {
            return value
        }
        set(60)
        return 60
    }
    
    func set(_ value: Int) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

