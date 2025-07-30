//
//  RealmScheduleExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation

extension [Schedule] {
    
    /// Creates a list of days with subsequent
    /// events for those days, merging multiple schedules
    func flattenAndMerge() -> [Day] {
        var days = [Day]()
        for schedule in self {
            days += schedule.days
        }
        
        var dayDictionary: [String : Day] = [:]
        for day in days {
            if let existingDay = dayDictionary[day.isoString] {
                existingDay.events.append(objectsIn: day.events)
                dayDictionary[day.isoString] = existingDay
            } else {
                let newDay = Day()
                newDay.name = day.name
                newDay.date = day.date
                newDay.isoString = day.isoString
                newDay.weekNumber = day.weekNumber
                newDay.events.append(objectsIn: day.events)
                dayDictionary[day.isoString] = newDay
            }
        }
        return Array<Day>(dayDictionary.values)
    }
    
    func filterEventsMatchingToday() -> [Event] {
        let now = Calendar.current.startOfDay(for: Date.now)
        let end = Calendar.current.endOfDay(for: Date.now)
        let dayRange = now...end

        var eventsForToday = [Event]()
        for event in self {
            guard event.toggled else {
                continue
            }

            for day in event.days {
                guard let eventDate = isoDateFormatterFract.date(from: day.isoString),
                      dayRange.contains(eventDate) else {
                    continue
                }

                eventsForToday.append(contentsOf: day.events)
            }
        }
        return eventsForToday
    }
    
    func findNextUpcomingEvent() -> Event? {
        let now = Date.now

        /// Filter schedules and flatten to get the list of events
        let events: [Event] = self
            .filter { $0.toggled }
            .flatMap { $0.days }
            .flatMap { $0.events }
        
        /// Parse dates and make pairs of (event, date)
        let eventDatePairs: [(event: Event, date: Date)] = events
            .compactMap { event in
                guard let date = isoDateFormatter.date(from: event.from) else {
                    return nil
                }
                return (event, date)
            }
        
        let sortedEventDatePairs = eventDatePairs.sorted(by: { $0.date < $1.date })
        
        /// Find the first event that is not today and after now
        let nextUpcomingEvent = sortedEventDatePairs.first(where: {
            $0.date > now
        })?.event
        
        return nextUpcomingEvent
    }

}

extension Schedule {
    
    func flatten() -> [Day] {
        return days.reduce(into: []) {
            if $1.isValidDay() { $0.append($1) }
        }
    }
    
    func isMissingEvents() -> Bool {
        for day in days {
            for event in day.events {
                if !event.title.isEmpty {
                    return false
                }
            }
        }
        return true
    }
}
