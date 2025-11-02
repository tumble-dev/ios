import Foundation
import SwiftUI

// MARK: - Network Namespace

enum Response {
    // MARK: - Models
    
    struct User: Codable, Equatable {
        let name: String
        let sessionId: String
        let username: String
        
        private enum CodingKeys: String, CodingKey {
            case name
            case sessionId = "session_id"
            case username
        }
    }
    
    struct Event: Codable, Equatable {
        let id: String
        let scheduleId: String
        let title: String
        let courseId: String
        let courseName: String
        let teachers: [Teacher]
        let from: Date
        let to: Date
        let locations: [Location]
        let lastModified: Date
        let isSpecial: Bool
        let colorHex: String
        
        var color: Color {
            Color(hex: colorHex)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case scheduleId = "schedule_id"
            case title
            case courseId = "course_id"
            case courseName = "course_name"
            case teachers
            case from
            case to
            case locations
            case lastModified = "last_modified"
            case isSpecial = "is_special"
            case colorHex = "color"
        }
    }
    
    struct EventsResponse: Codable, Equatable {
        let count: Int
        let events: [Response.Event]
    }
    
    struct NewsItem: Codable {
        let topic: String
        let title: String
        let body: String
        let longBody: String
        let timestamp: Date
        
        private enum CodingKeys: String, CodingKey {
            case topic
            case title
            case body
            case longBody = "long_body"
            case timestamp
        }
    }

    struct Teacher: Codable, Equatable {
        let id: String
        let firstName: String
        let lastName: String
        
        private enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName = "last_name"
        }
    }

    struct Location: Codable, Equatable {
        let id: String
        let name: String
        let building: String
        let floor: String
        let maxSeats: String
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case building
            case floor
            case maxSeats = "max_seats"
        }
    }
    
    struct ProgrammeSearchResponse: Codable {
        let count: Int
        let programmes: [Response.Programme]
    }

    struct Programme: Codable {
        let id: String
        let title: String
        let subtitle: String
    }

    // MARK: - Resource Models
    
    enum Availability: String, Codable, CaseIterable {
        case unavailable = "UNAVAILABLE"
        case available = "AVAILABLE"
        case booked = "BOOKED"
        
        func isValid() -> Bool {
            return Availability.allCases.contains(self)
        }
    }

    struct AvailabilitySlot: Codable, Equatable {
        let availability: Availability
        let locationId: String?
        let resourceType: String?
        let timeSlotId: Int?
        
        private enum CodingKeys: String, CodingKey {
            case availability
            case locationId = "location_id"
            case resourceType = "resource_type"
            case timeSlotId = "time_slot_id"
        }
    }

    struct Booking: Codable {
        let resourceId: String
        let timeSlot: TimeSlot?
        let locationId: String
        let showConfirmButton: Bool
        let showUnbookButton: Bool
        let confirmationOpen: Date?
        let confirmationClosed: Date?
        
        private enum CodingKeys: String, CodingKey {
            case resourceId = "resource_id"
            case timeSlot = "time_slot"
            case locationId = "location_id"
            case showConfirmButton = "show_confirm_button"
            case showUnbookButton = "show_unbook_button"
            case confirmationOpen = "confirmation_open"
            case confirmationClosed = "confirmation_closed"
        }
    }

    struct BookingRequest: Codable {
        let date: Date
        let slot: AvailabilitySlot?
    }

    struct ConfirmBookingRequest: Codable {
        let resourceId: String
    }

    struct Resource: Codable, Equatable {
        let id: String
        let name: String
        let timeSlots: [TimeSlot]?
        let date: Date?
        let locationIds: [String]?
        let availabilities: [String: [Int: AvailabilitySlot]]?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case timeSlots = "time_slots"
            case date
            case locationIds = "location_ids"
            case availabilities
        }
    }

    struct TimeSlot: Codable, Hashable {
        let id: Int?
        let from: Date
        let to: Date
        
        func duration() -> TimeInterval {
            return to.timeIntervalSince(from)
        }
        
        func timeString() -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "\(formatter.string(from: from))-\(formatter.string(from: to))"
        }
        
        static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
            if let lhsId = lhs.id, let rhsId = rhs.id {
                return lhsId == rhsId
            }
            
            if lhs.id == nil && rhs.id == nil {
                return lhs.from == rhs.from && lhs.to == rhs.to
            }
            
            return false
        }
        
        func hash(into hasher: inout Hasher) {
            if let id = id {
                hasher.combine(id)
            } else {
                hasher.combine(from)
                hasher.combine(to)
            }
        }
    }

    // MARK: - User Models
    
    struct LoginRequest: Codable {
        let username: String
        let password: String
    }

    struct UserEvent: Codable {
        let title: String
        let type: String
        let start: Date
        let end: Date
    }

    struct UserEventsResponse: Codable {
        let registered: [AvailableUserEvent]
        let unregistered: [AvailableUserEvent]
        let upcoming: [UpcomingUserEvent]
        
        private enum CodingKeys: String, CodingKey {
            case registered = "registered_events"
            case unregistered = "unregistered_events"
            case upcoming = "upcoming_events"
        }
    }

    struct AvailableUserEvent: Codable {
        let title: String
        let type: String
        let eventStart: Date
        let eventEnd: Date
        let id: String?
        let participatorId: String?
        let supportId: String?
        let anonymousCode: String
        let isRegistered: Bool
        let supportAvailable: Bool
        let requiresChoosingLocation: Bool
        let lastSignupDate: Date
        
        private enum CodingKeys: String, CodingKey {
            case title
            case type
            case eventStart = "event_start"
            case eventEnd = "event_end"
            case id
            case participatorId = "participator_id"
            case supportId = "support_id"
            case anonymousCode = "anonymous_code"
            case isRegistered = "is_registered"
            case supportAvailable = "support_available"
            case requiresChoosingLocation = "requires_choosing_location"
            case lastSignupDate = "last_signup_date"
        }
    }

    struct UpcomingUserEvent: Codable {
        let title: String
        let type: String
        let eventStart: Date
        let eventEnd: Date
        let firstSignupDate: Date
        
        private enum CodingKeys: String, CodingKey {
            case title
            case type
            case eventStart = "event_start"
            case eventEnd = "event_end"
            case firstSignupDate = "first_signup_date"
        }
    }
}
