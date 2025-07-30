//
//  SettingsOption.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

protocol SettingsOption: Identifiable {
    var displayName: String { get }
}

extension SettingsOption {
    var id: UUID {
        return UUID()
    }
}
