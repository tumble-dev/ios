//
//  BookmarksView.ViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine

typealias BookmarksViewModelType = StateStoreViewModel<BookmarksScreenViewState, BookmarksScreenViewAction>

class BookmarksViewModel: BookmarksViewModelType, ObservableObject {
    let appSettings: AppSettings
    let eventStorageService: EventStorageService
    
    private var actionsSubject: PassthroughSubject<BookmarksScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<BookmarksScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        eventStorageService: EventStorageService
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
        }
    }
    
    private func setupListeners() {
        eventStorageService.allEventsPublisher
            .sink { [weak self] allEvents in
                guard let self else { return }
                
                // 1. If allEvents is empty, set state.dataState = .empty
                guard !allEvents.isEmpty else {
                    state.dataState = .empty
                    return
                }
                
                // 2. Filter allEvents by their scheduleId to appSettings.hiddenScheduleIds
                let hiddenScheduleIds = appSettings.hiddenProgrammeIds
                let visibleEvents = allEvents.filter { event in
                    !hiddenScheduleIds.contains(event.scheduleId)
                }
                
                // Check if filtered events is empty, if so set state.dataState = .hidden
                guard !visibleEvents.isEmpty else {
                    state.dataState = .hidden
                    return
                }
                
                state.dataState = .loaded(visibleEvents)
            }
            .store(in: &cancellables)

    }
}
