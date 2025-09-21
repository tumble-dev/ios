//
//  Preferences.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

protocol PreferenceStorable {
    associatedtype ValueType
    func get() -> ValueType
    func set(_ value: ValueType)
}
