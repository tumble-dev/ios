//
//  EventExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Foundation

extension Event {
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        dictionary["title"] = title
        dictionary["schoolId"] = schoolId
        dictionary["from"] = from
        dictionary["to"] = to
        dictionary["eventId"] = eventId
        dictionary["isSpecial"] = isSpecial
        dictionary["lastModified"] = lastModified
        
        var courseDict: [String: String] = [:]
        courseDict["englishName"] = course?.englishName
        courseDict["swedishName"] = course?.englishName
        courseDict["courseId"] = course?.courseId
        courseDict["color"] = course?.color
        dictionary["course"] = courseDict
        
        var locationsArray: [[String: Any]] = []
        for location in locations {
            var locationDict: [String: Any] = [:]
            locationDict["name"] = location.name
            locationDict["locationId"] = location.locationId
            locationDict["building"] = location.building
            locationDict["floor"] = location.floor
            locationDict["maxSeats"] = location.maxSeats // Int
            locationsArray.append(locationDict)
        }
        dictionary["locations"] = locationsArray
        
        var teachersArray: [[String: String]] = []
        for teacher in teachers {
            var teacherDict: [String: String] = [:]
            teacherDict["firstName"] = teacher.firstName
            teacherDict["lastName"] = teacher.lastName
            teacherDict["teacherId"] = teacher.teacherId
            teachersArray.append(teacherDict)
        }
        dictionary["teachers"] = teachersArray
        
        return dictionary
    }
    
    func isValidEvent() -> Bool {
        let today = Date()
        guard let eventStartDate = dateFormatterEvent.date(from: from) else { return false }
        return Calendar.current.startOfDay(for: eventStartDate) >= Calendar.current.startOfDay(for: today)
    }
}

extension [Event] {
    func sorted() -> [Event] {
        return self.sorted(by: {
            // Ascending order
            if let fromFirst = dateFormatterEvent.date(from: $0.from),
               let fromSecond = dateFormatterEvent.date(from: $1.from) {
                return fromFirst < fromSecond
            }
            return false
        })
    }
    
    func removeDuplicates() -> [Event] {
        var eventIds = Set<String>()
        var uniqueEvents: [Event] = []
        for event in self {
            if eventIds.insert(event.eventId).inserted {
                uniqueEvents.append(event)
            }
        }
        
        return uniqueEvents
    }
}
