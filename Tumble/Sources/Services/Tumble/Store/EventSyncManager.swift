//
//  EventSyncManager.swift
//  Tumble
//
//  Created by Assistant on 2025-11-14.
//

import BackgroundTasks
import Combine
import Foundation
import Network

// MARK: - Sync Status

enum EventSyncStatus: Equatable {
    case idle
    case syncing
    case success
    case failed(Error)
    
    static func == (lhs: EventSyncStatus, rhs: EventSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.success, .success):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Sync Result

struct EventSyncResult {
    let newEvents: [Response.Event]
    let updatedEvents: [Response.Event]
    let removedEventIds: [String]
    let timestamp: Date
}

// MARK: - Event Sync Service Protocol

protocol EventSyncManagerProtocol {
    var syncStatus: CurrentValueSubject<EventSyncStatus, Never> { get }
    var lastSyncDate: Date? { get }
    
    func startPeriodicSync()
    func stopPeriodicSync()
    func performManualSync() async throws -> EventSyncResult
}

// MARK: - Event Sync Service

final class EventSyncManager: EventSyncManagerProtocol, ObservableObject {
    // MARK: - Properties
    
    private let apiService: TumbleApiServiceProtocol
    private let storageService: EventStorageServiceProtocol
    private let appSettings: AppSettings
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "network.monitor")
    
    @Published private(set) var isOnline = true
    @Published private(set) var lastSyncDate: Date?
    
    let syncStatus = CurrentValueSubject<EventSyncStatus, Never>(.idle)
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Background task identifier
    private static let backgroundTaskIdentifier = "com.tumble.background-sync"
    
    // MARK: - Initialization
    
    init(apiService: TumbleApiServiceProtocol,
         storageService: EventStorageServiceProtocol,
         appSettings: AppSettings)
    {
        self.apiService = apiService
        self.storageService = storageService
        self.appSettings = appSettings
        
        setupNetworkMonitoring()
        setupSettingsObserver()
        registerBackgroundTask()
        
        // Load last sync date
        if let lastSyncTimestamp = UserDefaults.standard.object(forKey: "lastEventSyncDate") as? Date {
            lastSyncDate = lastSyncTimestamp
        }
    }
    
    deinit {
        stopPeriodicSync()
        networkMonitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // MARK: - Settings Observer
    
    private func setupSettingsObserver() {
        // Restart sync when sync frequency changes
        appSettings.$syncFrequency
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.restartPeriodicSync()
            }
            .store(in: &cancellables)
        
        // Monitor background refresh setting
        appSettings.$backgroundRefreshEnabled
            .sink { [weak self] enabled in
                if enabled {
                    self?.startPeriodicSync()
                } else {
                    self?.stopPeriodicSync()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Background Task Registration
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundSync(task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundSync(_ task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                _ = try await performManualSync()
                task.setTaskCompleted(success: true)
            } catch {
                AppLogger.shared.error("Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
            
            // Schedule next background task
            scheduleBackgroundSync()
        }
    }
    
    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: nextSyncInterval())
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    // MARK: - Periodic Sync Management
    
    func startPeriodicSync() {
        guard appSettings.backgroundRefreshEnabled else { return }
        guard appSettings.syncFrequency != .manual else { return }
        
        stopPeriodicSync()
        
        let interval = nextSyncInterval()
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                try? await self?.performAutomaticSync()
            }
        }
        
        // Schedule background task for when app is backgrounded
        scheduleBackgroundSync()
        
        AppLogger.shared.info("Started periodic sync with interval: \(interval) seconds")
    }
    
    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
        
        AppLogger.shared.info("Stopped periodic sync")
    }
    
    private func restartPeriodicSync() {
        if appSettings.backgroundRefreshEnabled && appSettings.syncFrequency != .manual {
            startPeriodicSync()
        }
    }
    
    private func nextSyncInterval() -> TimeInterval {
        switch appSettings.syncFrequency {
        case .manual:
            return .greatestFiniteMagnitude
        case .hourly:
            return 3600 // 1 hour
        case .daily:
            return 86400 // 24 hours
        case .weekly:
            return 604800 // 7 days
        }
    }
    
    // MARK: - Sync Operations
    
    func performManualSync() async throws -> EventSyncResult {
        return try await performSync(isManual: true)
    }
    
    private func performAutomaticSync() async throws {
        _ = try await performSync(isManual: false)
    }
    
    private func performSync(isManual: Bool) async throws -> EventSyncResult {
        // Check preconditions
        guard isOnline || isManual else {
            throw NetworkError.noInternetConnection
        }
        
        if appSettings.wifiOnlyMode && !isConnectedToWiFi() && !isManual {
            throw NetworkError.wifiOnlyModeEnabled
        }
        
        // Update sync status on main thread
        await MainActor.run {
            syncStatus.send(.syncing)
        }
        
        do {
            let result = try await fetchEventsFromBackend()
            try await processEventChanges(result)
            
            // Update last sync date and status on main thread
            await MainActor.run {
                let now = Date()
                lastSyncDate = now
                UserDefaults.standard.set(now, forKey: "lastEventSyncDate")
                syncStatus.send(.success)
            }
            
            AppLogger.shared.info("Event sync completed successfully. New: \(result.newEvents.count), Updated: \(result.updatedEvents.count), Removed: \(result.removedEventIds.count)")
            
            return result
            
        } catch {
            // Update error status on main thread
            await MainActor.run {
                syncStatus.send(.failed(error))
            }
            AppLogger.shared.error("Event sync failed: \(error)")
            throw error
        }
    }
    
    private func fetchEventsFromBackend() async throws -> EventSyncResult {
        // Get the current events from storage for comparison
        let currentEvents = await withCheckedContinuation { continuation in
            storageService.getAllEvents { events in
                continuation.resume(returning: events)
            }
        }
        
        // Create a dictionary for quick lookup
        let currentEventsDict = Dictionary(uniqueKeysWithValues: currentEvents.map { ($0.id, $0) })
        
        // Group bookmarked programmes by school
        let visibleBookmarkedProgrammes = appSettings.getVisibleBookmarkedProgrammes()
        let schoolGroups = Dictionary(grouping: visibleBookmarkedProgrammes) { $0.value.schoolId }
        
        var allLatestEvents: [Response.Event] = []
        
        // Fetch events for each school
        for (schoolId, programmes) in schoolGroups {
            let scheduleIds = programmes.map { $0.key }
            
            do {
                let eventsResponse = try await apiService.getScheduleEvents(
                    school: schoolId,
                    scheduleIds: scheduleIds
                )
                allLatestEvents.append(contentsOf: eventsResponse.events)
            } catch {
                AppLogger.shared.error("Failed to fetch events for school \(schoolId): \(error)")
                // Continue with other schools even if one fails
                continue
            }
        }
        
        // Determine changes
        var newEvents: [Response.Event] = []
        var updatedEvents: [Response.Event] = []
        var removedEventIds: [String] = []
        
        let latestEventsDict = Dictionary(uniqueKeysWithValues: allLatestEvents.map { ($0.id, $0) })
        
        // Find new and updated events
        for latestEvent in allLatestEvents {
            if let currentEvent = currentEventsDict[latestEvent.id] {
                // Check if event was updated (you might want to compare timestamps or hash)
                if latestEvent != currentEvent {
                    updatedEvents.append(latestEvent)
                }
            } else {
                newEvents.append(latestEvent)
            }
        }
        
        // Find removed events (events that exist locally but not in the latest fetch)
        for currentEvent in currentEvents {
            if latestEventsDict[currentEvent.id] == nil {
                removedEventIds.append(currentEvent.id)
            }
        }
        
        return EventSyncResult(
            newEvents: newEvents,
            updatedEvents: updatedEvents,
            removedEventIds: removedEventIds,
            timestamp: Date()
        )
    }
    
    private func processEventChanges(_ result: EventSyncResult) async throws {
        // Process new events
        for event in result.newEvents {
            try storageService.saveEvent(event)
        }
        
        // Process updated events
        for event in result.updatedEvents {
            try storageService.saveEvent(event)
        }
        
        // Process removed events
        for eventId in result.removedEventIds {
            try storageService.removeEvent(id: eventId)
        }
    }
    
    // MARK: - Network Utilities
    
    private func isConnectedToWiFi() -> Bool {
        let path = networkMonitor.currentPath
        return path.status == .satisfied && path.usesInterfaceType(.wifi)
    }
}
