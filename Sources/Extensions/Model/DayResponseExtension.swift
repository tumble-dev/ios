//
//  DayResonseExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation

extension [Response.Day] {
    func ordered() -> [Response.Day] {
        return compactMap { $0 }.sorted(by: {
            // Ascending order
            if let fromFirst = isoDateFormatterFract.date(from: $0.isoString), let fromSecond = isoDateFormatterFract.date(from: $1.isoString) {
                return fromFirst < fromSecond
            }
            return false
        })
    }
}

extension Response.Day {
    func isValidDay() -> Bool {
        isoDateFormatterFract.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dayIsoString: String = isoString
        guard let day = isoDateFormatterFract.date(from: dayIsoString) else { return false }
        let today = Date()
        return Calendar.current.startOfDay(for: day) >= Calendar.current.startOfDay(for: today)
    }
}
