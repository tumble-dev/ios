//
//  DateExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-27.
//

import Foundation

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = gregorianCalendar) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = gregorianCalendar) -> Int {
        return calendar.component(component, from: self)
    }
    
    func formatDate() -> String {
        return dateFormatterComma.string(from: self)
    }
    
}
