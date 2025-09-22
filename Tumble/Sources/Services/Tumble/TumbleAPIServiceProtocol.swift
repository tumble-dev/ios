//
//  TumbleAPIServiceProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-21.
//

protocol TumbleApiServiceProtocol {
    func get<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T
    
    func post<T: Codable, U: Codable>(
        _ endpoint: TumbleEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T
    
    func post<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T
    
    func put<T: Codable, U: Codable>(
        _ endpoint: TumbleEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T
    
    func put<T: Codable>(
        _ endpoint: TumbleEndpoint,
        responseType: T.Type
    ) async throws -> T
    
    func performVoidRequest(_ endpoint: TumbleEndpoint) async throws
    
    // MARK: - Extension

    func getNews() async throws -> [Response.NewsItem]
    func login(credentials: Response.LoginRequest, school: String) async throws -> Response.User
    func getScheduleEvents(school: String, scheduleIds: [String]) async throws -> Response.EventsResponse
    func searchProgrammes(query: String, school: String) async throws -> Response.ProgrammeSearchResponse
    
    // MARK: - Authenticated Endpoints

    func getAllResources(school: String, date: String?, authToken: String) async throws -> [Response.Resource]
    func bookResource(resourceId: String, school: String, booking: Response.BookingRequest, authToken: String) async throws -> Response.Booking
    func getUserBookings(school: String, authToken: String) async throws -> [Response.Booking]
    func unbookResource(bookingId: String, school: String, authToken: String) async throws
    func getRegisteredEvents(school: String, authToken: String) async throws -> [Response.UserEvent]
    func getAvailableEvents(school: String, authToken: String) async throws -> [Response.UserEvent]
    func registerForEvent(eventId: String, school: String, authToken: String) async throws
    func unregisterFromEvent(eventId: String, school: String, authToken: String) async throws
}
