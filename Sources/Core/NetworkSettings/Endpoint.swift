//
//  Endpoint.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-27.
//

import Foundation

/// This file contains the endpoint structure for each
/// possible request. It dynamically generates url components
/// based on selected Endpoint case, and is then passed to the NetworkManager.
enum Endpoint {
    
    /// Tumble API
    case searchProgramme(searchQuery: String, schoolId: String)
    case schedule(scheduleId: String, schoolId: String)
    case userEvents(schoolId: String)
    case resourceAvailabilities(schoolId: String, resourceId: String, date: String)
    case allResources(schoolId: String, date: Date)
    case userBookings(schoolId: String)
    case login(schoolId: String)
    case users(schoolId: String)
    case registerAllEvents(schoolId: String)
    case registerEvent(eventId: String, schoolId: String)
    case unregisterEvent(eventId: String, schoolId: String)
    case bookResource(schoolId: String)
    case confirmResource(schoolId: String)
    case unbookResource(schoolId: String, bookingId: String)
    case news
    
    var url: URL {
        var components = URLComponents()
        components.host = NetworkSettings.shared.tumbleUrl
        components.port = NetworkSettings.shared.port
        components.scheme = NetworkSettings.shared.scheme
        
        switch self {
        case .searchProgramme(searchQuery: let searchQuery, schoolId: let schoolId):
            components.path = "/api/schedules/search"
            components.queryItems = [
                URLQueryItem(name: "searchQuery", value: searchQuery),
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .schedule(scheduleId: let scheduleId, schoolId: let schoolId):
            components.path = "/api/schedules/\(scheduleId)"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .userEvents(schoolId: let schoolId):
            components.path = "/api/users/events/"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .resourceAvailabilities(schoolId: let schoolId, resourceId: let resourceId, date: let date):
            components.path = "/api/resources/"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId),
                URLQueryItem(name: "resourceId", value: resourceId),
                URLQueryItem(name: "date", value: date)
            ]
        case .userBookings(schoolId: let schoolId):
            components.path = "/api/resources/userbookings"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .login(schoolId: let schoolId):
            components.path = "/api/users/login"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .users(schoolId: let schoolId):
            components.path = "/api/users"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .registerAllEvents(schoolId: let schoolId):
            components.path = "/api/users/events/register/all"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .registerEvent(eventId: let eventId, schoolId: let schoolId):
            components.path = "/api/users/events/register/\(eventId)"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .unregisterEvent(eventId: let eventId, schoolId: let schoolId):
            components.path = "/api/users/events/unregister/\(eventId)"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .news:
            components.path = "/api/misc/news"
        case .allResources(schoolId: let schoolId, date: let date):
            let localDate = convertToLocalDate(date: date)
            components.path = "/api/resources/all"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId),
                URLQueryItem(name: "date", value: isoDateFormatterResourceDate.string(from: localDate))
            ]
        case .bookResource(
            schoolId: let schoolId):
            components.path = "/api/resources/book"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        case .unbookResource(schoolId: let schoolId, bookingId: let bookingId):
            components.path = "/api/resources/unbook"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId),
                URLQueryItem(name: "bookingId", value: bookingId)
            ]
        case .confirmResource(schoolId: let schoolId):
            components.path = "/api/resources/confirm"
            components.queryItems = [
                URLQueryItem(name: "schoolId", value: schoolId)
            ]
        }
        
        return components.url!
    }
}
