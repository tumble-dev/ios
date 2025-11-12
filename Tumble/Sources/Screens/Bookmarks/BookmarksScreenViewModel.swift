//
//  BookmarksScreenViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import Foundation

typealias BookmarksScreenViewModelType = StateStoreViewModel<BookmarksScreenViewState, BookmarksScreenViewAction>

class BookmarksScreenViewModel: BookmarksScreenViewModelType, ObservableObject {
    let appSettings: AppSettings
    let eventStorageService: EventStorageServiceProtocol
    
    private var actionsSubject: PassthroughSubject<BookmarksScreenViewModelAction, Never> = .init()
    private var loadingHistoricalEvents = false
    private var earliestLoadedEventDate: Date?
    @Published private var historicalDaysLoaded: Int = 0 // Track how many days back we've loaded
    
    // Configuration for incremental loading
    private let initialHistoricalDays = 3  // Load 3 days back initially
    private let incrementalDays = 7        // Then load 7 more days each time
    private let maxHistoricalDays = 90     // Maximum 90 days back
    
    var actions: AnyPublisher<BookmarksScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        eventStorageService: EventStorageServiceProtocol
    ) {
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        super.init(initialViewState: .init())
        
        setupListeners()
    }
    
    override func process(viewAction: BookmarksScreenViewAction) {
        switch viewAction {
        case .openEvent(let eventId):
            actionsSubject.send(.presentEventDetails(eventId: eventId))
        case .showSearch:
            actionsSubject.send(.presentSearchScreen)
        case .showSettings:
            actionsSubject.send(.presentSettingsScreen)
        case .showAccount:
            actionsSubject.send(.presentAccountScreen)
        case .changeViewType(let viewType):
            appSettings.bookmarkViewType = viewType
        case .loadHistoricalEvents:
            loadHistoricalEvents()
        }
    }
    
    private func loadHistoricalEvents() {
        guard !loadingHistoricalEvents else { return }
        guard historicalDaysLoaded < maxHistoricalDays else { return } // Don't load beyond max limit
        
        loadingHistoricalEvents = true
        
        Task.detached { [weak self] in
            // Small delay to show refresh animation
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.loadingHistoricalEvents = false
                
                // Increment historical days loaded
                let increment = self.historicalDaysLoaded == 0 ? self.initialHistoricalDays : self.incrementalDays
                self.historicalDaysLoaded = min(self.historicalDaysLoaded + increment, self.maxHistoricalDays)
                
                AppLogger.shared.info("Loaded historical events: \(self.historicalDaysLoaded) days back")
            }
        }
    }
    
    private func setupListeners() {
        // Use allEventsPublisher to get initial values and updates
        Publishers.CombineLatest4(
            eventStorageService.allEventsPublisher,
            appSettings.$bookmarkedProgrammes,
            appSettings.$bookmarkViewType,
            $historicalDaysLoaded
        )
        .sink { [weak self] allEvents, bookmarkedProgrammes, viewType, historicalDaysLoaded in
            guard let self else { return }
            
            state.bookmarksViewType = viewType
            
            guard !allEvents.isEmpty else {
                state.dataState = .empty
                return
            }
            
            let enabledProgrammeIds = Set(bookmarkedProgrammes.compactMap { key, value in
                value ? key : nil
            })
            
            let visibleEvents = allEvents.filter { event in
                enabledProgrammeIds.contains(event.scheduleId)
            }
            
            guard !visibleEvents.isEmpty else {
                state.dataState = .hidden
                return
            }
            
            // Apply incremental filtering based on how many days back we've loaded
            let filteredEvents = self.filterEventsWithIncrementalHistory(visibleEvents, daysBack: historicalDaysLoaded)
            
            state.dataState = .loaded(filteredEvents)
        }
        .store(in: &cancellables)
    }
    
    // Filter events with incremental historical loading
    private func filterEventsWithIncrementalHistory(_ events: [Response.Event], daysBack: Int) -> [Response.Event] {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        
        // If no historical days loaded, show only future events
        guard daysBack > 0 else {
            return events.filter { $0.from >= startOfToday }
                .sorted { $0.from < $1.from }
        }
        
        // Calculate the cutoff date for historical events
        let historicalCutoff = calendar.date(byAdding: .day, value: -daysBack, to: startOfToday) ?? startOfToday
        
        // Get future events (from today onwards)
        let futureEvents = events.filter { $0.from >= startOfToday }
            .sorted { $0.from < $1.from }
        
        // Get historical events within the loaded range
        let historicalEvents = events.filter { event in
            event.from >= historicalCutoff && event.from < startOfToday
        }.sorted { $0.from > $1.from } // Most recent historical events first
        
        // Combine: historical events first, then future events
        return historicalEvents + futureEvents
    }
}
