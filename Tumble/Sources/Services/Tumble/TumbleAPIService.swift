//
//  TumbleAPIService.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

// MARK: - Network Swift.Error

enum NetworkError: Swift.Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Swift.Error)
    case encodingError(Swift.Error)
    case serverError(Int, Data?)
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case noInternetConnection
    case unknown(Swift.Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let code, _):
            return "Server error (HTTP \(code))"
        case .unauthorized:
            return "Unauthorized - Please login again"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Result

typealias APIResult<T> = Result<T, NetworkError>

// MARK: - Request Configuration

struct RequestConfig {
    let timeout: TimeInterval
    let retryCount: Int
    let retryDelay: TimeInterval
    
    static let `default` = RequestConfig(
        timeout: 30,
        retryCount: 3,
        retryDelay: 1.0
    )
}

// MARK: - API Response Wrapper

struct APIResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
    let success: Bool
    let timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case data, message, success, timestamp
    }
}

// MARK: - Empty Response for endpoints that return no data

struct EmptyResponse: Codable {
    let success: Bool
    let message: String?
    
    init() {
        success = true
        message = nil
    }
}

// MARK: - Tumble API Service

final class TumbleAPIService: TumbleApiServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let config: RequestConfig
    
    init(config: RequestConfig = .default) {
        self.config = config
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        sessionConfig.timeoutIntervalForResource = config.timeout * 2
        sessionConfig.waitsForConnectivity = true
        session = URLSession(configuration: sessionConfig)
        
        decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - Generic Request Methods
    
    /// Performs a GET request
    func get<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequest(endpoint, responseType: responseType)
    }
    
    /// Performs a POST request with body
    func post<T: Codable, U: Codable>(
        _ endpoint: TumbleEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequestWithBody(endpoint, body: body, responseType: responseType)
    }
    
    /// Performs a POST request without body
    func post<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequest(endpoint, responseType: responseType)
    }
    
    /// Performs a PUT request with body
    func put<T: Codable, U: Codable>(
        _ endpoint: TumbleEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequestWithBody(endpoint, body: body, responseType: responseType)
    }
    
    /// Performs a PUT request without body
    func put<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequest(endpoint, responseType: responseType)
    }
    
    func delete<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequest(endpoint, responseType: responseType)
    }
    
    /// Performs a request without expecting a response body (returns success status)
    func performVoidRequest(_ endpoint: TumbleEndpoint) async throws {
        let _: EmptyResponse = try await performRequest(endpoint, responseType: EmptyResponse.self)
    }
    
    // MARK: - Private Implementation
    
    private func performRequest<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        let startTime = Date()
        let endpointName = getEndpointName(endpoint)
        
        do {
            let request = endpoint.urlRequest()
            AppLogger.shared.info("API Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")")
            
            // Log API request
            ServiceLocator.shared.analytics.logEvent("api_request", parameters: [
                "endpoint": endpointName,
                "method": request.httpMethod ?? "GET",
                "retry_count": retryCount
            ])
            
            // Log headers for debugging
            AppLogger.shared.info("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let (data, response) = try await session.data(for: request)
            
            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.shared.info("Response: HTTP \(httpResponse.statusCode)")
                AppLogger.shared.info("Response Headers: \(httpResponse.allHeaderFields)")
                
                let duration = Date().timeIntervalSince(startTime)
                let responseSize = data.count
                
                // Log successful API response
                ServiceLocator.shared.analytics.logEvent("api_response", parameters: [
                    "endpoint": endpointName,
                    "method": request.httpMethod ?? "GET",
                    "status_code": httpResponse.statusCode,
                    "duration_ms": Int(duration * 1000),
                    "response_size_bytes": responseSize,
                    "retry_count": retryCount
                ])
            }
            
            return try handleResponse(data: data, response: response, responseType: responseType)
        } catch {
            AppLogger.shared.error("Request failed: \(error)")
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Log API error
            ServiceLocator.shared.analytics.logEvent("api_error", parameters: [
                "endpoint": endpointName,
                "method": endpoint.httpMethod.rawValue,
                "error_type": mapNetworkErrorForAnalytics(error),
                "duration_ms": Int(duration * 1000),
                "retry_count": retryCount,
                "will_retry": shouldRetry(error: mapError(error)) && retryCount < config.retryCount
            ])
            
            return try await handleRequestError(error, endpoint: endpoint, responseType: responseType, retryCount: retryCount)
        }
    }
    
    private func performRequestWithBody<T: Codable, U: Codable>(
        _ endpoint: TumbleEndpoint,
        body: U,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        let startTime = Date()
        let endpointName = getEndpointName(endpoint)
        
        do {
            var request = endpoint.urlRequest()
            
            do {
                let bodyData = try encoder.encode(body)
                request.httpBody = bodyData
                
                // Log request with body info
                ServiceLocator.shared.analytics.logEvent("api_request", parameters: [
                    "endpoint": endpointName,
                    "method": request.httpMethod ?? "POST",
                    "has_body": true,
                    "body_size_bytes": bodyData.count,
                    "retry_count": retryCount
                ])
                
            } catch {
                ServiceLocator.shared.analytics.logEvent("api_encoding_error", parameters: [
                    "endpoint": endpointName,
                    "error_type": "request_encoding"
                ])
                throw NetworkError.encodingError(error)
            }
            
            let (data, response) = try await session.data(for: request)
            
            // Log response
            if let httpResponse = response as? HTTPURLResponse {
                let duration = Date().timeIntervalSince(startTime)
                
                ServiceLocator.shared.analytics.logEvent("api_response", parameters: [
                    "endpoint": endpointName,
                    "method": request.httpMethod ?? "POST",
                    "status_code": httpResponse.statusCode,
                    "duration_ms": Int(duration * 1000),
                    "response_size_bytes": data.count,
                    "retry_count": retryCount
                ])
            }
            
            return try handleResponse(data: data, response: response, responseType: responseType)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            ServiceLocator.shared.analytics.logEvent("api_error", parameters: [
                "endpoint": endpointName,
                "method": endpoint.httpMethod.rawValue,
                "error_type": mapNetworkErrorForAnalytics(error),
                "duration_ms": Int(duration * 1000),
                "retry_count": retryCount,
                "will_retry": shouldRetry(error: mapError(error)) && retryCount < config.retryCount
            ])
            
            return try await handleRequestErrorWithBody(error, endpoint: endpoint, body: body, responseType: responseType, retryCount: retryCount)
        }
    }
    
    private func getEndpointName(_ endpoint: TumbleEndpoint) -> String {
        // Extract a clean endpoint name for analytics
        switch endpoint {
        case .news:
            return "news"
        case .loginKronox:
            return "login"
        case .scheduleEvents:
            return "schedule_events"
        case .searchProgrammes:
            return "search_programmes"
        case .userBookings:
            return "user_bookings"
        case .bookResource:
            return "book_resource"
        case .unbookResource:
            return "unbook_resource"
        case .confirmResourceBooking:
            return "confirm_resource_booking"
        case .registeredEvents:
            return "registered_events"
        case .registerEvent:
            return "register_event"
        case .unregisterEvent:
            return "unregister_event"
        case .allResources:
            return "all_resources"
        case .availableEvents:
            return "available_events"
        }
    }

    private func mapNetworkErrorForAnalytics(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                return "invalid_url"
            case .noData:
                return "no_data"
            case .decodingError:
                return "decoding_error"
            case .encodingError:
                return "encoding_error"
            case .serverError(let code, _):
                return "server_error_\(code)"
            case .unauthorized:
                return "unauthorized"
            case .forbidden:
                return "forbidden"
            case .notFound:
                return "not_found"
            case .timeout:
                return "timeout"
            case .noInternetConnection:
                return "no_internet"
            case .unknown:
                return "unknown_network_error"
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "no_internet"
            case .timedOut:
                return "timeout"
            case .cannotFindHost:
                return "cannot_find_host"
            case .cannotConnectToHost:
                return "cannot_connect_to_host"
            case .networkConnectionLost:
                return "connection_lost"
            default:
                return "url_error_\(urlError.code.rawValue)"
            }
        }
        
        return "unknown_error"
    }
    
    private struct APIErrorResponse: Codable {
        let error: String
    }
    
    private func handleResponse<T: Codable>(
        data: Data,
        response: URLResponse,
        responseType: T.Type
    ) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 400, 500...599:
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                AppLogger.shared.error("API Error (\(httpResponse.statusCode)): \(apiError.error)")
                throw NetworkError.serverError(httpResponse.statusCode, data)
            } else {
                AppLogger.shared.error("API Error (\(httpResponse.statusCode)): Unable to parse error")
                throw NetworkError.serverError(httpResponse.statusCode, data)
            }
        case 401:
            AppLogger.shared.error("Unauthorized (401): Invalid or expired credentials")
            throw NetworkError.unauthorized
        case 403:
            AppLogger.shared.error("Forbidden (403): Access denied")
            throw NetworkError.forbidden
        case 404:
            AppLogger.shared.error("Not Found (404): Resource missing")
            throw NetworkError.notFound
        case 408:
            AppLogger.shared.error("Timeout (408): Request timed out")
            throw NetworkError.timeout
        default:
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                AppLogger.shared.error("API Error (\(httpResponse.statusCode)): \(apiError.error)")
                throw NetworkError.serverError(httpResponse.statusCode, data)
            } else {
                AppLogger.shared.error("API Error (\(httpResponse.statusCode)): Unknown error")
                throw NetworkError.serverError(httpResponse.statusCode, data)
            }
        }
        
        // Handle empty responses for void operations
        if responseType == EmptyResponse.self && data.isEmpty {
            return EmptyResponse() as! T
        }
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            // Try to decode as wrapped response first
            if let wrappedResponse = try? decoder.decode(APIResponse<T>.self, from: data),
               let actualData = wrappedResponse.data
            {
                return actualData
            }
            
            throw NetworkError.decodingError(error)
        }
    }

    private func handleRequestError<T: Codable>(
        _ error: Swift.Error,
        endpoint: TumbleEndpoint,
        responseType: T.Type,
        retryCount: Int
    ) async throws -> T {
        let networkError = mapError(error)
        
        if shouldRetry(error: networkError) && retryCount < config.retryCount {
            try await Task.sleep(nanoseconds: UInt64(config.retryDelay * 1_000_000_000))
            return try await performRequest(endpoint, responseType: responseType, retryCount: retryCount + 1)
        }
        
        throw networkError
    }
    
    private func handleRequestErrorWithBody<T: Codable, U: Codable>(
        _ error: Swift.Error,
        endpoint: TumbleEndpoint,
        body: U,
        responseType: T.Type,
        retryCount: Int
    ) async throws -> T {
        let networkError = mapError(error)
        
        if shouldRetry(error: networkError) && retryCount < config.retryCount {
            try await Task.sleep(nanoseconds: UInt64(config.retryDelay * 1000000000))
            return try await performRequestWithBody(endpoint, body: body, responseType: responseType, retryCount: retryCount + 1)
        }
        
        throw networkError
    }
    
    private func mapError(_ error: Swift.Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .timeout
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
    
    private func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .timeout, .noInternetConnection:
            return true
        case .serverError(let code, _):
            return code >= 500 // Retry server errors
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions for Common Patterns

extension TumbleAPIService {
    // MARK: - News

    func getNews() async throws -> [Response.NewsItem] {
        return try await get(.news, responseType: [Response.NewsItem].self)
    }
    
    // MARK: - Authentication

    func login(credentials: Response.LoginRequest, school: String) async throws -> Response.User {
        return try await post(.loginKronox(school: school), body: credentials, responseType: Response.User.self)
    }
    
    // MARK: - Schedule

    func getScheduleEvents(school: String, scheduleIds: [String]) async throws -> Response.EventsResponse {
        return try await get(.scheduleEvents(school: school, scheduleIds: scheduleIds), responseType: Response.EventsResponse.self)
    }
    
    // MARK: - Programme Search

    func searchProgrammes(query: String, school: String) async throws -> Response.ProgrammeSearchResponse {
        return try await get(.searchProgrammes(query: query, school: school), responseType: Response.ProgrammeSearchResponse.self)
    }
}

// MARK: - Authenticated Endpoints

extension TumbleAPIService {

    func getUserBookings(school: String, authToken: String) async throws -> [Response.Booking] {
        let endpoint = TumbleEndpoint.userBookings(school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: [Response.Booking].self)
    }
    
    func bookResource(
        resourceId: String,
        school: String,
        booking: Response.BookingRequest,
        authToken: String
    ) async throws -> Response.GenericResponse {
        let endpoint = TumbleEndpoint.bookResource(resourceId: resourceId, school: school)
        var request = endpoint.urlRequest(authToken: authToken)
        request.httpBody = try encoder.encode(booking)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: Response.GenericResponse.self)
    }
    
    func unbookResource(bookingId: String, school: String, authToken: String) async throws -> Response.GenericResponse {
        let endpoint = TumbleEndpoint.unbookResource(bookingId: bookingId, school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: Response.GenericResponse.self)
    }
    

    func confirmResourceBooking(
        bookingId: String,
        school: String,
        authToken: String
    ) async throws -> Response.GenericResponse {
        let endpoint = TumbleEndpoint.confirmResourceBooking(bookingId: bookingId, school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: Response.GenericResponse.self)
    }

    func getRegisteredEvents(school: String, authToken: String) async throws -> [Response.UserEvent] {
        let endpoint = TumbleEndpoint.registeredEvents(school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: [Response.UserEvent].self)
    }
    
    func registerForEvent(eventId: String, school: String, authToken: String) async throws {
        let endpoint = TumbleEndpoint.registerEvent(eventId: eventId, school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        let _: EmptyResponse = try handleResponse(data: data, response: response, responseType: EmptyResponse.self)
    }
    
    func unregisterFromEvent(eventId: String, school: String, authToken: String) async throws {
        let endpoint = TumbleEndpoint.unregisterEvent(eventId: eventId, school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        let _: EmptyResponse = try handleResponse(data: data, response: response, responseType: EmptyResponse.self)
    }
    
    func getAllResources(school: String, date: String, authToken: String) async throws -> [Response.Resource] {
        let endpoint = TumbleEndpoint.allResources(school: school, date: date)
        let request = endpoint.urlRequest(authToken: authToken)
        AppLogger.shared.info("Request: \(request)")
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: [Response.Resource].self)
    }
    
    func getAvailableEvents(school: String, authToken: String) async throws -> [Response.UserEvent] {
        let endpoint = TumbleEndpoint.availableEvents(school: school)
        let request = endpoint.urlRequest(authToken: authToken)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response, responseType: [Response.UserEvent].self)
    }
}
