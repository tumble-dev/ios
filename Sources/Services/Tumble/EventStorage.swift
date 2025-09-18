//
//  EventStorageEvent.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import Foundation
import Combine

// MARK: - Event Storage Change Types
enum EventStorageEvent {
    case eventAdded(event: Response.Event)
    case eventUpdated(event: Response.Event, previousEvent: Response.Event?)
    case eventRemoved(eventId: String, removedEvent: Response.Event)
    case eventsCleared
    case batchEventsAdded(events: [Response.Event])
    case batchEventsUpdated(events: [Response.Event])
}

// MARK: - Event Storage Error Types
enum EventStorageError: Error, LocalizedError {
    case fileOperationFailed
    case eventNotFound(id: String)
    case encodingFailed
    case decodingFailed
    case invalidEventData
    
    var errorDescription: String? {
        switch self {
        case .fileOperationFailed:
            return "File operation failed"
        case .eventNotFound(let id):
            return "Event with ID '\(id)' not found"
        case .encodingFailed:
            return "Failed to encode event data"
        case .decodingFailed:
            return "Failed to decode event data"
        case .invalidEventData:
            return "Invalid event data"
        }
    }
}

// MARK: - Event Document Storage
class EventStorageService: ObservableObject {
    
    // MARK: - Properties
    private let fileURL: URL
    private let queue = DispatchQueue(label: "event.storage.queue", attributes: .concurrent)
    private var events: [String: Response.Event] = [:] // eventId -> Event
    
    @Published private(set) var lastChangeEvent: EventStorageEvent?
    private let changeSubject = PassthroughSubject<EventStorageEvent, Never>()
    
    private let allEventsSubject = CurrentValueSubject<[Response.Event], Never>([])
    
    var changePublisher: AnyPublisher<EventStorageEvent, Never> {
        changeSubject.eraseToAnyPublisher()
    }
    
    var allEventsPublisher: AnyPublisher<[Response.Event], Never> {
        allEventsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(filename: String = "events_storage.json") {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        self.fileURL = documentsPath.appendingPathComponent(filename)
        loadFromDisk()
        
        // Ensure subject is initialized with loaded events
        allEventsSubject.send(Array(events.values))
    }
    
    // MARK: - Helpers
    private func publishEvents() {
        let snapshot = queue.sync { Array(events.values) }
        DispatchQueue.main.async {
            self.allEventsSubject.send(snapshot)
        }
    }
    
    // MARK: - Core Event Operations
    
    /// Store or update an event
    func saveEvent(_ event: Response.Event) throws {
        try queue.sync(flags: .barrier) {
            let previousEvent = events[event.id]
            events[event.id] = event
            try saveToDisk()
            
            let changeEvent: EventStorageEvent = previousEvent == nil ? 
                .eventAdded(event: event) : 
                .eventUpdated(event: event, previousEvent: previousEvent)
            
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishEvents()
            }
        }
    }
    
    /// Get an event by ID
    func getEvent(id: String) -> Response.Event? {
        return queue.sync {
            return events[id]
        }
    }
    
    /// Remove an event by ID
    func removeEvent(id: String) throws {
        try queue.sync(flags: .barrier) {
            guard let removedEvent = events.removeValue(forKey: id) else {
                throw EventStorageError.eventNotFound(id: id)
            }
            
            try saveToDisk()
            
            let changeEvent = EventStorageEvent.eventRemoved(eventId: id, removedEvent: removedEvent)
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishEvents()
            }
        }
    }
    
    /// Remove all events for a given scheduleId
    func removeEvents(forScheduleId scheduleId: String) throws {
        try queue.sync(flags: .barrier) {
            // Find all events with matching scheduleId
            let matchingEvents = events.values.filter { $0.scheduleId == scheduleId }
            
            guard !matchingEvents.isEmpty else {
                throw EventStorageError.eventNotFound(id: scheduleId)
            }
            
            // Remove them from the dictionary
            for event in matchingEvents {
                events.removeValue(forKey: event.id)
            }
            
            // Save updated state
            try saveToDisk()
            
            // Notify subscribers
            DispatchQueue.main.async {
                for event in matchingEvents {
                    let changeEvent = EventStorageEvent.eventRemoved(eventId: event.id, removedEvent: event)
                    self.changeSubject.send(changeEvent)
                    self.publishEvents()
                }
            }
        }
    }
    
    /// Check if event exists
    func eventExists(id: String) -> Bool {
        return queue.sync {
            return events[id] != nil
        }
    }
    
    /// Clear all events
    func clearAllEvents() throws {
        try queue.sync(flags: .barrier) {
            events.removeAll()
            try saveToDisk()
            
            let changeEvent = EventStorageEvent.eventsCleared
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishEvents()
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Save multiple events at once
    func saveEvents(_ eventsToSave: [Response.Event]) throws {
        try queue.sync(flags: .barrier) {
            var isUpdate = false
            
            for event in eventsToSave {
                if events[event.id] != nil {
                    isUpdate = true
                }
                events[event.id] = event
            }
            
            try saveToDisk()
            
            let changeEvent: EventStorageEvent = isUpdate ? 
                .batchEventsUpdated(events: eventsToSave) : 
                .batchEventsAdded(events: eventsToSave)
            
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishEvents()
            }
        }
    }
    
    /// Get multiple events by IDs
    func getEvents(ids: [String]) -> [Response.Event] {
        return queue.sync {
            return ids.compactMap { events[$0] }
        }
    }
    
    /// Remove multiple events by IDs
    func removeEvents(ids: [String]) throws {
        try queue.sync(flags: .barrier) {
            var removedEvents: [Response.Event] = []
            
            for id in ids {
                if let event = events.removeValue(forKey: id) {
                    removedEvents.append(event)
                }
            }
            
            guard !removedEvents.isEmpty else {
                throw EventStorageError.eventNotFound(id: "Multiple IDs")
            }
            
            try saveToDisk()
            
            // Send individual removal events
            DispatchQueue.main.async {
                for event in removedEvents {
                    let changeEvent = EventStorageEvent.eventRemoved(eventId: event.id, removedEvent: event)
                    self.changeSubject.send(changeEvent)
                    self.publishEvents() 
                }
            }
        }
    }
    
    // MARK: - Query Operations
    
    /// Get events filtered by predicate
    func getEvents(where predicate: (Response.Event) -> Bool) -> [Response.Event] {
        return queue.sync {
            return events.values.filter(predicate)
        }
    }
    
    /// Get events for a specific course
    func getEvents(forCourse courseId: String) -> [Response.Event] {
        return getEvents { $0.courseId == courseId }
    }
    
    /// Get events within a date range
    func getEvents(from startDate: Date, to endDate: Date) -> [Response.Event] {
        return getEvents { event in
            return event.from >= startDate && event.to <= endDate
        }
    }
    
    /// Get events for today
    func getTodaysEvents() -> [Response.Event] {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return getEvents(from: startOfDay, to: endOfDay)
    }
    
    /// Get upcoming events (from now)
    func getUpcomingEvents(limit: Int? = nil) -> [Response.Event] {
        let now = Date()
        let upcomingEvents = getEvents { $0.from >= now }
            .sorted { $0.from < $1.from }
        
        if let limit = limit {
            return Array(upcomingEvents.prefix(limit))
        }
        return upcomingEvents
    }
    
    /// Get events modified after a specific date
    func getEventsModifiedAfter(_ date: Date) -> [Response.Event] {
        return getEvents { $0.lastModified > date }
    }
    
    /// Get special events
    func getSpecialEvents() -> [Response.Event] {
        return getEvents { $0.isSpecial }
    }
    
    // MARK: - Sorting and Grouping
    
    /// Get all events sorted by start date
    func getAllEventsSorted() -> [Response.Event] {
        return queue.sync {
            return events.values.sorted { $0.from < $1.from }
        }
    }
    
    /// Get events grouped by course
    
    
    /// Get events grouped by date (day)
    func getEventsGroupedByDate() -> [String: [Response.Event]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return queue.sync {
            return Dictionary(grouping: events.values) { event in
                formatter.string(from: event.from)
            }
        }
    }
    
    // MARK: - File Operations
    
    private func loadFromDisk() {
        queue.sync(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Load as array and convert to dictionary
                let eventArray = try decoder.decode([Response.Event].self, from: data)
                events = Dictionary(uniqueKeysWithValues: eventArray.map { ($0.id, $0) })
            } catch {
                print("Failed to load event storage: \(error)")
                events = [:]
            }
        }
    }
    
    private func saveToDisk() throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            // Save as array for better JSON structure
            let eventArray = Array(events.values)
            let data = try encoder.encode(eventArray)
            try data.write(to: fileURL)
        } catch {
            throw EventStorageError.fileOperationFailed
        }
    }
    
    // MARK: - Debug and Utility
    
    /// Get storage file path
    func getStorageFilePath() -> String {
        return fileURL.path
    }
    
    /// Get storage file size
    func getStorageFileSize() -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}
