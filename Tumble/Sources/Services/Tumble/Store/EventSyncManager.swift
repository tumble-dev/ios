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

// MARK: - Notification Extensions

extension Notification.Name {
    static let backgroundTaskHandlerRegistered = Notification.Name("backgroundTaskHandlerRegistered")
}

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
    func handleBackgroundSync(_ task: BGAppRefreshTask)
    
    static func markBackgroundTaskHandlerAsRegistered()
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
    
    // Track if background task handler is registered
    private static var isBackgroundTaskHandlerRegistered = false
    
    // Track initialization state
    private var isInitializing = true
    
    // MARK: - Public Methods for Background Task Management
    
    static func markBackgroundTaskHandlerAsRegistered() {
        isBackgroundTaskHandlerRegistered = true
        AppLogger.shared.info("Background task handler registered successfully for identifier: \(backgroundTaskIdentifier)")
        
        // Log current registration status for debugging
        AppLogger.shared.info("Background task registration status - Registered: \(isBackgroundTaskHandlerRegistered)")
    }
    
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
        setupBackgroundTaskNotificationObserver()
        
        // Load last sync date
        if let lastSyncTimestamp = UserDefaults.standard.object(forKey: "lastEventSyncDate") as? Date {
            lastSyncDate = lastSyncTimestamp
        }
        
        // Mark initialization as complete
        isInitializing = false
        AppLogger.shared.info("EventSyncManager initialization completed")
        
        // Start periodic sync if it should be enabled
        if appSettings.backgroundRefreshEnabled && appSettings.syncFrequency != .manual {
            AppLogger.shared.info("Auto-starting periodic sync - Background refresh enabled: \(appSettings.backgroundRefreshEnabled), Frequency: \(appSettings.syncFrequency)")
            startPeriodicSync()
        } else {
            AppLogger.shared.info("Periodic sync not started - Background refresh: \(appSettings.backgroundRefreshEnabled), Frequency: \(appSettings.syncFrequency)")
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
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied
                
                // Log network status changes
                if wasOnline != (self?.isOnline ?? false) {
                    let connectionType = self?.getConnectionType(from: path) ?? "Unknown"
                    AppLogger.shared.info("Network status changed to: \(self?.isOnline == true ? "Connected" : "Disconnected") (\(connectionType))")
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
        AppLogger.shared.info("Network monitoring started")
    }
    
    // MARK: - Settings Observer
    
    private func setupSettingsObserver() {
        // Restart sync when sync frequency changes
        appSettings.$syncFrequency
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, !self.isInitializing else { return }
                self.restartPeriodicSync()
            }
            .store(in: &cancellables)
        
        // Monitor background refresh setting
        appSettings.$backgroundRefreshEnabled
            .sink { [weak self] enabled in
                guard let self = self, !self.isInitializing else { return }
                
                if enabled {
                    self.startPeriodicSync()
                } else {
                    self.stopPeriodicSync()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Background Task Handler Registration Observer
    
    private func setupBackgroundTaskNotificationObserver() {
        // This method is kept for future use but currently not needed
        // The defensive scheduling approach should handle the registration timing
    }
    
    // MARK: - Background Task Handling
    
    func handleBackgroundSync(_ task: BGAppRefreshTask) {
        AppLogger.shared.info("Background sync task started - ID: \(task.identifier)")
        
        task.expirationHandler = {
            AppLogger.shared.warning("Background sync task expired before completion")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                let startTime = Date()
                let result = try await performManualSync()
                let duration = Date().timeIntervalSince(startTime)
                
                AppLogger.shared.info("Background sync completed successfully in \(String(format: "%.2f", duration))s - New: \(result.newEvents.count), Updated: \(result.updatedEvents.count), Removed: \(result.removedEventIds.count)")
                task.setTaskCompleted(success: true)
            } catch {
                AppLogger.shared.error("Background sync failed: \(error.localizedDescription)")
                
                // Log specific error types for better debugging
                if let networkError = error as? NetworkError {
                    AppLogger.shared.error("Background sync network error: \(networkError)")
                }
                
                task.setTaskCompleted(success: false)
            }
            
            // Schedule next background task regardless of success/failure
            scheduleBackgroundSync()
        }
    }
    
    private func scheduleBackgroundSync() {
        // Only schedule background tasks if the handler has been properly registered
        guard Self.isBackgroundTaskHandlerRegistered else {
            AppLogger.shared.warning("Background task handler not yet registered, skipping scheduling for identifier: \(Self.backgroundTaskIdentifier)")
            return
        }
        
        let interval = nextSyncInterval()
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            AppLogger.shared.info("Background sync scheduled successfully - Next execution in \(interval) seconds")
        } catch {
            AppLogger.shared.error("Failed to schedule background sync: \(error.localizedDescription)")
            
            // Log additional details about the error
            if let bgError = error as? BGTaskScheduler.Error {
                switch bgError.code {
                case .unavailable:
                    AppLogger.shared.error("Background task scheduling unavailable")
                case .tooManyPendingTaskRequests:
                    AppLogger.shared.error("Too many pending background task requests")
                case .notPermitted:
                    AppLogger.shared.error("Background task scheduling not permitted")
                default:
                    AppLogger.shared.error("Unknown background task scheduling error: \(bgError.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Periodic Sync Management
    
    func startPeriodicSync() {
        guard appSettings.backgroundRefreshEnabled else { 
            AppLogger.shared.info("Periodic sync not started - background refresh disabled")
            return 
        }
        guard appSettings.syncFrequency != .manual else { 
            AppLogger.shared.info("Periodic sync not started - manual sync mode")
            return 
        }
        
        stopPeriodicSync()
        
        let interval = nextSyncInterval()
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                do {
                    try await self?.performAutomaticSync()
                } catch {
                    AppLogger.shared.error("Automatic sync failed: \(error.localizedDescription)")
                }
            }
        }
        
        // Schedule background task for when app is backgrounded
        scheduleBackgroundSync()
        
        AppLogger.shared.info("Started periodic sync with interval: \(interval) seconds (\(formatSyncInterval(interval)))")
    }
    
    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        
        // Only cancel background tasks if they were previously scheduled
        // This prevents issues during app initialization
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
    
    private func formatSyncInterval(_ interval: TimeInterval) -> String {
        switch interval {
        case 3600:
            return "1 hour"
        case 86400:
            return "1 day"
        case 604800:
            return "1 week"
        default:
            return "\(Int(interval)) seconds"
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
    
    private func getConnectionType(from path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "Wi-Fi"
        } else if path.usesInterfaceType(.cellular) {
            return "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        } else if path.usesInterfaceType(.other) {
            return "Other"
        } else {
            return "Unknown"
        }
    }
}
