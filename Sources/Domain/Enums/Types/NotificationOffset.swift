//
//  NotificationOffset.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

enum NotificationOffset: Int, SettingsOption {
    case fifteen = 15
    case thirty = 30
    case hour = 60
    case threeHours = 180
    
    var displayName: String {
        return String(format: "%d %@", self.rawValue, NSLocalizedString("minutes", comment: ""))
    }
    
    static var allCases: [NotificationOffset] = [.fifteen, .thirty, .hour, .threeHours]
}
