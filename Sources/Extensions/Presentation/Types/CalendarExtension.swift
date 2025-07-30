//
//  CalendarExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-05-28.
//

import Foundation

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        var components = self.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return self.date(from: components) ?? date
    }
}
