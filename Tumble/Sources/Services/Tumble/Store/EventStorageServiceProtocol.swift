//
//  EventStorageServiceProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-21.
//

import Combine
import Foundation

protocol EventStorageServiceProtocol {
    var changePublisher: AnyPublisher<EventStorageEvent, Never> { get }
    var allEventsPublisher: AnyPublisher<[Response.Event], Never> { get }
    
    func saveEvent(_ event: Response.Event) throws
    func getEvent(id: String) -> Response.Event?
    func removeEvent(id: String) throws
    func removeEvents(forProgrammeId programmeId: String) throws
    
    func eventExists(id: String) -> Bool
    func clearAllEvents() throws
    func saveEvents(_ eventsToSave: [Response.Event]) throws
    func getEvents(ids: [String]) -> [Response.Event]
    func removeEvents(ids: [String]) throws
    
    func getEvents(where predicate: (Response.Event) -> Bool) -> [Response.Event]
    func getEvents(forCourse courseId: String) -> [Response.Event]
    func getEvents(from startDate: Date, to endDate: Date) -> [Response.Event]
    func getTodaysEvents() -> [Response.Event]
    func getUpcomingEvents(limit: Int?) -> [Response.Event]
    func getEventsModifiedAfter(_ date: Date) -> [Response.Event]
    func getSpecialEvents() -> [Response.Event]
    func getAllEventsSorted() -> [Response.Event]
    func getEventsGroupedByDate() -> [String: [Response.Event]]
    
    func updateColor(forCourse courseId: String, withColor colorHex: String)
}
