//
//  Response.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-27.
//

import Foundation

public enum Response {
    // MARK: - Message

    struct Message: Codable {
        let message: String
    }
    
    struct Empty: Codable {}
    
    // ------ SCHEDULE ------
    // ----------------------
    
    // MARK: - Schedule

    struct Schedule: Encodable, Decodable, Hashable {
        static func == (lhs: Response.Schedule, rhs: Response.Schedule) -> Bool {
            return lhs.id == rhs.id
        }
        
        let id, cachedAt: String
        let days: [Day]
        
        var hasEvents: Bool {
            return days.contains { !$0.events.isEmpty }
        }
    }

    // MARK: - Day

    struct Day: Encodable, Decodable, Hashable {
        static func == (lhs: Response.Day, rhs: Response.Day) -> Bool {
            return lhs.name == rhs.name && lhs.isoString == rhs.isoString && lhs.weekNumber == rhs.weekNumber
        }

        let name: String
        let date, isoString: String
        let weekNumber: Int
        let events: [Event]
        
        var id: UUID {
            return UUID()
        }
    }

    // MARK: - Event

    struct Event: Encodable, Decodable, Equatable, Hashable, Identifiable {
        static func == (lhs: Response.Event, rhs: Response.Event) -> Bool {
            return lhs.id == rhs.id
        }
        
        let title: String
        let course: Course
        let from, to: String
        let locations: [Location]
        let teachers: [Teacher]
        let id: String
        let isSpecial: Bool
        let lastModified: String
    }

    // MARK: - Course

    struct Course: Encodable, Decodable, Hashable {
        let id: String
        let swedishName, englishName: String
    }

    // MARK: - Location

    struct Location: Encodable, Decodable, Hashable {
        let id: String
        let name: String
        let building, floor: String
        let maxSeats: Int
    }

    // MARK: - Teacher

    struct Teacher: Encodable, Decodable, Hashable {
        let id: String
        let firstName: String
        let lastName: String
    }
    
    // ------ SEARCH ------
    // --------------------

    // MARK: - SearchResponse

    struct Search: Encodable, Decodable {
        let count: Int
        let items: [Programme]
    }

    // MARK: - Item

    struct Programme: Encodable, Decodable {
        let id, title, subtitle: String
    }
    
    // ------ USER ------
    // ------------------

    // MARK: - UserSession

    struct KronoxUser: Encodable, Decodable {
        let name, username: String
    }
    
    struct SessionDetails: Encodable, Decodable {
        let sessionToken: String
        let sessionLocation: String
    }
    
    // ------ KronoX events ------
    // --------------------------

    // MARK: - KronoxCompleteUserEvent

    struct KronoxCompleteUserEvent: Encodable, Decodable {
        let upcomingEvents: [UpcomingKronoxUserEvent]?
        let registeredEvents, unregisteredEvents: [AvailableKronoxUserEvent]?
    }

    // MARK: - AvailableKronoxUserEvent

    struct AvailableKronoxUserEvent: Identifiable, Encodable, Decodable {
        var id: UUID = .init()
        
        let eventId, title, type: String?
        let eventStart, eventEnd, lastSignupDate: String
        let participatorID, supportID: String?
        let anonymousCode: String
        let isRegistered, supportAvailable, requiresChoosingLocation: Bool

        enum CodingKeys: String, CodingKey {
            case eventId = "id"
            case title, type, eventStart, eventEnd, lastSignupDate
            case participatorID = "participatorId"
            case supportID = "supportId"
            case anonymousCode, isRegistered, supportAvailable, requiresChoosingLocation
        }
    }

    // MARK: - UpcomingKronoxUserEvent

    struct UpcomingKronoxUserEvent: Identifiable, Encodable, Decodable {
        let title, type: String
        let eventStart, eventEnd, firstSignupDate: String
        
        var id: UUID {
            return UUID()
        }
    }
    
    // ------ KronoX resources

    // MARK: - KronoxCompleteSchoolResourceElement

    struct KronoxCompleteUserResource: Encodable, Decodable {
        let id, name: String
        let timeSlots, locationIDS, date, availabilities: Nullable.JSONNull?

        enum CodingKeys: String, CodingKey {
            case id, name, timeSlots
            case locationIDS = "locationIds"
            case date, availabilities
        }
    }
    
    typealias Availabilities = [String: [Int: AvailabilityValue]]?
    
    typealias KronoxResources = [KronoxResourceElement]

    // MARK: - KronoxResourceElement

    struct KronoxResourceElement: Codable {
        let id, name: String?
        let timeSlots: [TimeSlot]?
        let date: String?
        let locationIDS: [String]?
        let availabilities: Availabilities

        enum CodingKeys: String, CodingKey {
            case id, name, timeSlots, date
            case locationIDS = "locationIds"
            case availabilities
        }
    }

    // MARK: - AvailabilityValue

    struct AvailabilityValue: Codable, Hashable {
        static func == (lhs: Response.AvailabilityValue, rhs: Response.AvailabilityValue) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        let availability: AvailabilityEnum?
        let locationID, resourceType, timeSlotID, bookedBy: String?

        enum CodingKeys: String, CodingKey {
            case availability
            case locationID = "locationId"
            case resourceType
            case timeSlotID = "timeSlotId"
            case bookedBy
        }
    }

    enum AvailabilityEnum: String, Codable {
        case unavailable = "UNAVAILABLE"
        case booked = "BOOKED"
        case available = "AVAILABLE"
    }

    // MARK: - TimeSlot

    struct TimeSlot: Codable, Hashable {
        static func == (lhs: Response.TimeSlot, rhs: Response.TimeSlot) -> Bool {
            return lhs.id == rhs.id
        }
        
        let id: Int?
        let from, to, duration: String?
    }

    typealias KronoxUserBookings = [KronoxUserBookingElement]
    
    // MARK: - KronoxUserBookingElement

    struct KronoxUserBookingElement: Identifiable, Decodable {
        let id, resourceID: String
        let timeSlot: TimeSlot
        let locationID: String
        let showConfirmButton, showUnbookButton: Bool
        let confirmationOpen, confirmationClosed: String?

        enum CodingKeys: String, CodingKey {
            case id
            case resourceID = "resourceId"
            case timeSlot
            case locationID = "locationId"
            case showConfirmButton, showUnbookButton, confirmationOpen, confirmationClosed
        }
        
        var dateComponentsConfirmation: DateComponents? {
            guard let confirmationOpen = confirmationOpen else {
                return nil
            }
            guard let date = dateFormatterFull.date(from: confirmationOpen) else {
                return nil
            }
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            return dateComponents
        }
    }
    
    // MARK: - KronoxEventRegistration

    struct KronoxEventRegistration: Codable {
        let successfulRegistrations, failedRegistrations: [Registration]?
    }

    // MARK: - Registration

    struct Registration: Codable {
        let id, title, type: String?
        let eventStart, eventEnd, lastSignupDate: String?
        let participatorID, supportID, anonymousCode: String?
        let isRegistered, supportAvailable, requiresChoosingLocation: Bool?

        enum CodingKeys: String, CodingKey {
            case id, title, type, eventStart, eventEnd, lastSignupDate
            case participatorID = "participatorId"
            case supportID = "supportId"
            case anonymousCode, isRegistered, supportAvailable, requiresChoosingLocation
        }
    }
    
    // MARK: - ErrorMessage

    struct ErrorMessage: Codable, LocalizedError {
        let message: String
        var statusCode: Int? = nil
    }
    
    typealias NewsItems = [NotificationContent]

    // MARK: - NotificationContent

    struct NotificationContent: Codable, Hashable {
        static func == (lhs: Response.NotificationContent, rhs: Response.NotificationContent) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        let topic: String
        let title: String
        let body: String
        let longBody: String?
        let timestamp: String // ISO date string
    }
}
