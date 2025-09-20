//
//  EventStorageService.swift
// Tumble
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
    case programmeNotFound(id: String)
    case encodingFailed
    case decodingFailed
    case invalidEventData
    case compressionFailed
    case decompressionFailed
    
    var errorDescription: String? {
        switch self {
        case .fileOperationFailed:
            return "File operation failed"
        case .eventNotFound(let id):
            return "Event with ID '\(id)' not found"
        case .programmeNotFound(let id):
            return "Events with programme identifier '\(id)' not found"
        case .encodingFailed:
            return "Failed to encode event data"
        case .decodingFailed:
            return "Failed to decode event data"
        case .invalidEventData:
            return "Invalid event data"
        case .compressionFailed:
            return "Failed to compress data"
        case .decompressionFailed:
            return "Failed to decompress data"
        }
    }
}

// MARK: - Storage Format Types
enum StorageFormat {
    case standard
    case optimized
}

// MARK: - Event Document Storage
class EventStorageService: ObservableObject {
    
    // MARK: - Properties
    private let standardFileURL: URL
    private let optimizedFileURL: URL
    private let queue = DispatchQueue(label: "event.storage.queue", attributes: .concurrent)
    private var events: [String: Response.Event] = [:] // eventId -> Event
    private let appSettings: AppSettings
    private var cancellables = Set<AnyCancellable>()
    
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
    init(filename: String = "events_storage", appSettings: AppSettings) {
        self.appSettings = appSettings
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        self.standardFileURL = documentsPath.appendingPathComponent("\(filename).json")
        self.optimizedFileURL = documentsPath.appendingPathComponent("\(filename)_compressed.json")
        
        loadFromDisk()
        allEventsSubject.send(Array(events.values))
        
        setupStorageOptimizationObserver()
    }
    
    // MARK: - Storage Optimization Observer
    private func setupStorageOptimizationObserver() {
        appSettings.$storageOptimizationEnabled
            .sink { [weak self] isEnabled in
                self?.handleStorageOptimizationChange(isEnabled)
            }
            .store(in: &cancellables)
    }
    
    private func handleStorageOptimizationChange(_ isOptimized: Bool) {
        queue.async(flags: .barrier) {
            do {
                try self.migrateStorageFormat(toOptimized: isOptimized)
            } catch {
                AppLogger.shared.info("Failed to migrate storage format: \(error)")
            }
        }
    }
    
    // MARK: - Storage Migration
    private func migrateStorageFormat(toOptimized: Bool) throws {
        let sourceURL = toOptimized ? standardFileURL : optimizedFileURL
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return }
        
        if toOptimized {
            try saveOptimizedFormat()
        } else {
            try saveStandardFormat()
        }
        
        // Remove old format file after successful migration
        try? FileManager.default.removeItem(at: sourceURL)
        
        AppLogger.shared.info("Migrated storage format to \(toOptimized ? "compressed" : "standard")")
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
    
    /// Remove all events for a given programmeId
    func removeEvents(forProgrammeId programmeId: String) throws {
        try queue.sync(flags: .barrier) {
            let matchingEvents = events.values.filter { $0.scheduleId == programmeId }
            
            guard !matchingEvents.isEmpty else {
                throw EventStorageError.programmeNotFound(id: programmeId)
            }
            
            for event in matchingEvents {
                events.removeValue(forKey: event.id)
            }
            
            try saveToDisk()
            
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
            let isOptimized = appSettings.storageOptimizationEnabled
            let fileURL = isOptimized ? optimizedFileURL : standardFileURL
            
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                let fallbackURL = isOptimized ? standardFileURL : optimizedFileURL
                guard FileManager.default.fileExists(atPath: fallbackURL.path) else { return }
                
                loadFromFile(fallbackURL, isOptimized: !isOptimized)
                return
            }
            
            loadFromFile(fileURL, isOptimized: isOptimized)
        }
    }
    
    private func loadFromFile(_ url: URL, isOptimized: Bool) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let jsonData: Data
            if isOptimized {
                jsonData = try (data as NSData).decompressed(using: .lzfse) as Data
            } else {
                jsonData = data
            }
            
            let eventArray = try decoder.decode([Response.Event].self, from: jsonData)
            events = Dictionary(uniqueKeysWithValues: eventArray.map { ($0.id, $0) })
            
            AppLogger.shared.info("Loaded \(events.count) events from \(isOptimized ? "compressed" : "standard") storage")
        } catch {
            AppLogger.shared.info("Failed to load events from \(url.path): \(error)")
            events = [:]
        }
    }
    
    private func saveToDisk() throws {
        if appSettings.storageOptimizationEnabled {
            try saveOptimizedFormat()
        } else {
            try saveStandardFormat()
        }
    }
    
    private func saveStandardFormat() throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let eventArray = Array(events.values)
            let data = try encoder.encode(eventArray)
            try data.write(to: standardFileURL)
        } catch {
            throw EventStorageError.fileOperationFailed
        }
    }
    
    private func saveOptimizedFormat() throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let eventArray = Array(events.values)
            let jsonData = try encoder.encode(eventArray)
            
            let compressedData = try (jsonData as NSData).compressed(using: .lzfse) as Data
            try compressedData.write(to: optimizedFileURL)
        } catch {
            throw EventStorageError.fileOperationFailed
        }
    }
    
    // MARK: - Storage Stats
    func getStorageStats() -> (standardSize: Int64?, optimizedSize: Int64?, currentFormat: StorageFormat) {
        let standardSize = getFileSize(standardFileURL)
        let optimizedSize = getFileSize(optimizedFileURL)
        let currentFormat: StorageFormat = appSettings.storageOptimizationEnabled ? .optimized : .standard
        
        return (standardSize, optimizedSize, currentFormat)
    }
    
    private func getFileSize(_ url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    // MARK: - Storage Info for UI
    func getStorageInfo() -> String {
        let stats = getStorageStats()
        let currentSize = stats.currentFormat == .optimized ? stats.optimizedSize : stats.standardSize
        
        if let size = currentSize {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            let formattedSize = formatter.string(fromByteCount: size)
            return "\(formattedSize) (\(stats.currentFormat == .optimized ? "Compressed" : "Standard"))"
        }
        
        return "No storage file"
    }
    
    // MARK: - Debug and Utility
    
    /// Get storage file path
    func getStorageFilePath() -> String {
        let currentURL = appSettings.storageOptimizationEnabled ? optimizedFileURL : standardFileURL
        return currentURL.path
    }
    
    /// Get storage file size
    func getStorageFileSize() -> Int64? {
        let currentURL = appSettings.storageOptimizationEnabled ? optimizedFileURL : standardFileURL
        return getFileSize(currentURL)
    }
}
