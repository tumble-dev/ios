//
//  Endpoints.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-08.
//

import Foundation

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - API Endpoint Protocol
protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var httpMethod: HTTPMethod { get }
    var headers: [String: String] { get }
}

extension APIEndpoint {
    var url: URL {
        var components = URLComponents(string: baseURL)!
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            fatalError("Invalid URL components: \(components)")
        }
        return url
    }
    
    func urlRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Tumble-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(Config.apiKey, forHTTPHeaderField: "X-API-Key")
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}

// MARK: - Tumble API Endpoints
enum TumbleEndpoint {
    // News
    case news
    
    // Schedule
    case scheduleEvents(school: String, scheduleIds: [String]? = nil)
    
    // Authentication
    case loginKronox(school: String)
    
    // Programme Search
    case searchProgrammes(query: String, school: String)
    
    // Resources
    case allResources(school: String, date: String? = nil)
    case bookResource(resourceId: String, school: String)
    case userBookings(school: String)
    case unbookResource(bookingId: String, school: String)
    
    // Events
    case registeredEvents(school: String)
    case availableEvents(school: String)
    case registerEvent(eventId: String, school: String)
    case unregisterEvent(eventId: String, school: String)
}

extension TumbleEndpoint: APIEndpoint {
    var baseURL: String {
        let settings = NetworkSettings.Environments.development
        let url = "\(settings.scheme)://\(settings.tumbleUrl):\(settings.port)"
        AppLogger.shared.info("Base URL: \(url)")
        return url
    }
    
    var path: String {
        switch self {
        case .news:
            return "/api/v1/news"
        case .scheduleEvents:
            return "/api/v1/schedule/events"
        case .loginKronox:
            return "/api/v1/auth/kronox/login"
        case .searchProgrammes:
            return "/api/v1/programme/search"
        case .allResources:
            return "/api/v1/resources/all"
        case .bookResource(let resourceId, _):
            return "/api/v1/resources/\(resourceId)/bookings"
        case .userBookings:
            return "/api/v1/resources/bookings"
        case .unbookResource(let bookingId, _):
            return "/api/v1/resources/bookings/\(bookingId)"
        case .registeredEvents:
            return "/api/v1/events/registered"
        case .availableEvents:
            return "/api/v1/events/available"
        case .registerEvent(let eventId, _):
            return "/api/v1/events/\(eventId)/register"
        case .unregisterEvent(let eventId, _):
            return "/api/v1/events/\(eventId)/unregister"
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .news:
            return []
        case .scheduleEvents(let school, let scheduleIds):
            var items = [URLQueryItem(name: "school", value: school)]
            if let ids = scheduleIds {
                items.append(contentsOf: ids.map { URLQueryItem(name: "schedule_ids", value: $0) })
            }
            return items
        case .loginKronox(let school):
            return [URLQueryItem(name: "school", value: school)]
        case .searchProgrammes(let query, let school):
            AppLogger.shared.info("[TumbleEndpoint] Searching for \(query) using school \(school)")
            return [
                URLQueryItem(name: "search_query", value: query),
                URLQueryItem(name: "school", value: school)
            ]
        case .allResources(let school, let date):
            var items = [URLQueryItem(name: "school", value: school)]
            if let date = date {
                items.append(URLQueryItem(name: "date", value: date))
            }
            return items
        case .bookResource(_, let school):
            return [URLQueryItem(name: "school", value: school)]
        case .userBookings(let school):
            return [URLQueryItem(name: "school", value: school)]
        case .unbookResource(_, let school):
            return [URLQueryItem(name: "school", value: school)]
        case .registeredEvents(let school):
            return [URLQueryItem(name: "school", value: school)]
        case .availableEvents(let school):
            return [URLQueryItem(name: "school", value: school)]
        case .registerEvent(_, let school):
            return [URLQueryItem(name: "school", value: school)]
        case .unregisterEvent(_, let school):
            return [URLQueryItem(name: "school", value: school)]
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .news, .scheduleEvents, .searchProgrammes, .allResources,
             .userBookings, .registeredEvents, .availableEvents:
            return .GET
        case .loginKronox, .bookResource, .registerEvent:
            return .POST
        case .unregisterEvent:
            return .PUT
        case .unbookResource:
            return .DELETE
        }
    }
    
    var headers: [String: String] {
        return [:]
    }
}
