//
//  DateCollections.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-06-07.
//

import Foundation

var weekStartDates: [Date] {
    let calendar = Calendar.current
    var result: [Date] = []
    let startDate = Date.now

    // Find the nearest past Monday
    let currentWeekday = calendar.component(.weekday, from: startDate)
    let daysToSubtract = (currentWeekday + 5) % 7
    let nearestMonday = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate)!

    var currentDate = nearestMonday
    let endDate = calendar.date(byAdding: .month, value: 6, to: nearestMonday)!

    while currentDate <= endDate {
        result.append(currentDate)
        currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
    }

    return result
}
