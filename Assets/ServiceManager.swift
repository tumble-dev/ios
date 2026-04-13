//
//  ServiceManager.swift
//  Tumble
//
//  Created by Assistant on 2025-11-14.
//

import BackgroundTasks
import Combine
import Foundation

// MARK: - Event Sync Manager

/// Simple background sync manager that integrates with existing ServiceLocator pattern
final class EventSyncManager: NSObject, ObservableObject {
    // MARK: - Singleton
    
    static let shared = EventSyncManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var syncStatus: EventSyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Private Properties
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Background task identifier
    private static let backgroundTaskIdentifier = "com.tumble.background-sync"
    
    // MARK: - Dependencies (from ServiceLocator)
    
    private var apiService: TumbleApiServiceProtocol {
        ServiceLocator.shared.tumbleApiService
    }
    
    private var eventStorageService: EventStorageServiceProtocol {
        ServiceLocator.shared.eventStorageService
    }
    
    private var appSettings: AppSettings {
        ServiceLocator.shared.settings
    }
    
    private var networkMonitor: NetworkMonitorProtocol {
        ServiceLocator.shared.networkMonitor
    }
    
    // MARK: - Initialization
    
    override private init() {
        super.init()
        
        // Load last sync date
        lastSyncDate = UserDefaults.standard.object(forKey: "lastEventSyncDate") as? Date
        
        registerBackgroundTask()
        setupSettingsObserver()
    }
    
    // MARK: - Public Methods
    
    /// Start the sync manager - call this after ServiceLocator is configured
    func start() {
        // Start automatic syncing if enabled
        if appSettings.backgroundRefreshEnabled && appSettings.syncFrequency != .manual {
            startPeriodicSync()
        }
    }
    
    /// Stop all sync activities
    func stop() {
        stopPeriodicSync()
    }
    
    /// Perform manual sync
    @MainActor
    func performManualSync() async throws -> EventSyncResult {
        return try await performSync(isManual: true)
    }
    
    // MARK: - Settings Observer
    
    private func setupSettingsObserver() {
        // Restart sync when sync frequency changes
        appSettings.$syncFrequency
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.restartPeriodicSyncIfNeeded()
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
        
        Task { @MainActor in
            do {
                _ = try await performSync(isManual: false)
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
    
    private func startPeriodicSync() {
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
    
    private func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
        
        AppLogger.shared.info("Stopped periodic sync")
    }
    
    private func restartPeriodicSyncIfNeeded() {
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
    
    @MainActor
    private func performAutomaticSync() async throws {
        _ = try await performSync(isManual: false)
    }
    
    @MainActor
    private func performSync(isManual: Bool) async throws -> EventSyncResult {
        // Check preconditions
        let currentReachability = networkMonitor.reachabilityPublisher.value
        guard currentReachability.isReachable || isManual else {
            throw NetworkError.noInternetConnection
        }
        
        if appSettings.wifiOnlyMode && !currentReachability.isWifiOrWired && !isManual {
            throw NetworkError.wifiOnlyModeEnabled
        }
        
        // Update sync status
        syncStatus = .syncing
        
        do {
            let result = try await fetchEventsFromBackend()
            try await processEventChanges(result)
            
            // Update last sync date
            let now = Date()
            lastSyncDate = now
            UserDefaults.standard.set(now, forKey: "lastEventSyncDate")
            
            syncStatus = .success
            AppLogger.shared.info("Event sync completed successfully. New: \(result.newEvents.count), Updated: \(result.updatedEvents.count), Removed: \(result.removedEventIds.count)")
            
            return result
            
        } catch {
            syncStatus = .failed(error)
            AppLogger.shared.error("Event sync failed: \(error)")
            throw error
        }
    }
    
    private func fetchEventsFromBackend() async throws -> EventSyncResult {
        // Get current events from storage for comparison
        let currentEvents = await withCheckedContinuation { continuation in
            eventStorageService.getAllEvents { events in
                continuation.resume(returning: events)
            }
        }
        
        // Create a dictionary for quick lookup
        let currentEventsDict = Dictionary(uniqueKeysWithValues: currentEvents.map { ($0.id, $0) })
        
        // TODO: Implement the actual API call to fetch latest events
        // For now, this is a placeholder that you'll need to implement based on your API
        let latestEvents: [Response.Event] = []
        
        // Determine changes
        var newEvents: [Response.Event] = []
        var updatedEvents: [Response.Event] = []
        var removedEventIds: [String] = []
        
        let latestEventsDict = Dictionary(uniqueKeysWithValues: latestEvents.map { ($0.id, $0) })
        
        // Find new and updated events
        for latestEvent in latestEvents {
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
            try eventStorageService.saveEvent(event)
        }
        
        // Process updated events
        for event in result.updatedEvents {
            try eventStorageService.saveEvent(event)
        }
        
        // Process removed events
        for eventId in result.removedEventIds {
            try eventStorageService.removeEvent(id: eventId)
        }
    }
}

// MARK: - Convenience Methods for UI

extension EventSyncManager {
    /// Get formatted sync status for UI display
    func getSyncStatusText() -> String {
        switch syncStatus {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .success:
            if let lastSync = lastSyncDate {
                return "Last sync: \(formatSyncDate(lastSync))"
            } else {
                return "Sync completed"
            }
        case .failed(let error):
            return "Sync failed: \(error.localizedDescription)"
        }
    }
    
    /// Get next scheduled sync time
    func getNextSyncTime() -> Date? {
        guard appSettings.backgroundRefreshEnabled,
              appSettings.syncFrequency != .manual,
              let lastSync = lastSyncDate
        else {
            return nil
        }
        
        let interval: TimeInterval
        switch appSettings.syncFrequency {
        case .manual:
            return nil
        case .hourly:
            interval = 3600
        case .daily:
            interval = 86400
        case .weekly:
            interval = 604800
        }
        
        return lastSync.addingTimeInterval(interval)
    }
    
    private func formatSyncDate(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}
