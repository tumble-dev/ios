//
//  EventDetailsScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine

typealias EventDetailsScreenViewModelType = StateStoreViewModel<EventDetailsScreenViewState, EventDetailsScreenViewAction>

class EventDetailsScreenViewModel: EventDetailsScreenViewModelType, ObservableObject {

    private let eventId: String
    private let appSettings: AppSettings
    private let eventStorageService: EventStorageServiceProtocol
    private let notificationManager: NotificationManagerProtocol
    
    private var actionsSubject: PassthroughSubject<EventDetailsScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<EventDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        eventId: String,
        appSettings: AppSettings,
        eventStorageService: EventStorageServiceProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.eventId = eventId
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        self.notificationManager = notificationManager
        super.init(initialViewState: .init())
    }
    
    private func fetchEvent(eventId: String) {
        if let event: Response.Event = eventStorageService.getEvent(id: eventId) {
            state.dataState = .loaded(event: event)
        } else {
            state.dataState = .error(msg: "Couldn't load event from storage.")
        }
    }
    
    override func process(viewAction: EventDetailsScreenViewAction) {
        switch viewAction {
        case .loadEvent:
            fetchEvent(eventId: eventId)
        case .close:
            actionsSubject.send(.close)
        case .showColorPicker:
            break // TODO: Show color picker
        }
    }
    
}
