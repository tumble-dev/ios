//
//  OnboardingPreference.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class OnboardingPreference: PreferenceStorable {
    typealias ValueType = Bool
    var key: SharedPreferenceKey = .userOnboarded
    
    func get() -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}



