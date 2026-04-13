//
//  Event.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation

extension [Response.Event] {
    func groupByDate() -> [DateGroup] {
        let calendar = Calendar.current
        
        // Group events by date
        let grouped = Dictionary(grouping: self) { event in
            calendar.startOfDay(for: event.from)
        }
        
        return grouped
            .sorted { $0.key < $1.key }
            .map { DateGroup(date: $0.key, events: $0.value.sorted { $0.from < $1.from }) }
    }
}

extension Response.Event {
    func withUpdatedColor(_ colorHex: String) -> Response.Event {
        Response.Event(
            id: id,
            scheduleId: scheduleId,
            title: title,
            courseId: courseId,
            courseName: courseName,
            teachers: teachers,
            from: from,
            to: to,
            locations: locations,
            lastModified: lastModified,
            isSpecial: isSpecial,
            colorHex: colorHex
        )
    }
}
