//
//  BookmarksScreenViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine

typealias BookmarksScreenViewModelType = StateStoreViewModel<BookmarksScreenViewState, BookmarksScreenViewAction>

class BookmarksScreenViewModel: BookmarksScreenViewModelType, ObservableObject {
    let appSettings: AppSettings
    let eventStorageService: EventStorageServiceProtocol
    
    private var actionsSubject: PassthroughSubject<BookmarksScreenViewModelAction, Never> = .init()
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
        }
    }
    
    private func setupListeners() {
        Publishers.CombineLatest3(
            eventStorageService.allEventsPublisher,
            appSettings.$bookmarkedProgrammes,
            appSettings.$bookmarkViewType
        )
        .sink { [weak self] allEvents, bookmarkedProgrammes, viewType in
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
            
            state.dataState = .loaded(visibleEvents)
        }
        .store(in: &cancellables)
    }
}
