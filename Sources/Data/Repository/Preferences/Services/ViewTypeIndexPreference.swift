//
//  ViewTypePreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class ViewTypeIndexPreference: PreferenceStorable {
    typealias ValueType = Int
    var key: SharedPreferenceKey = .viewType
    
    func get() -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue)
    }
    
    func set(_ value: Int) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

