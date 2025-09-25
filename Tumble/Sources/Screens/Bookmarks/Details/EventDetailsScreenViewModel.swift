//
//  EventDetailsScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import SwiftUI
import UIKit

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
    
    // Debounced color update pipeline
    private let colorUpdateSubject = PassthroughSubject<(courseId: String, hex: String), Never>()
    
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
        
        setupColorUpdateDebounce()
    }
    
    private func setupColorUpdateDebounce() {
        colorUpdateSubject
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates { lhs, rhs in
                lhs.courseId == rhs.courseId && lhs.hex == rhs.hex
            }
            .sink { [weak self] payload in
                guard let self else { return }
                self.eventStorageService.updateColor(forCourse: payload.courseId, withColor: payload.hex)
                self.fetchEvent(eventId: self.eventId)
            }
            .store(in: &cancellables)
    }
    
    private func fetchEvent(eventId: String) {
        if let event: Response.Event = eventStorageService.getEvent(id: eventId) {
            state.dataState = .loaded(event: event)
            // Initialize local picker state from the current event color
            state.bindings.colorPickerLocalSelection = event.color
            // Rebuild the ColorPicker binding to use the local state (fast) and debounce persistence
            state.bindings.colorPickerSelection = createColorPickerBinding(for: event)
        } else {
            state.dataState = .error(msg: "Couldn't load event from storage.")
            state.bindings.colorPickerLocalSelection = .clear
            state.bindings.colorPickerSelection = .constant(.clear)
        }
    }
    
    override func process(viewAction: EventDetailsScreenViewAction) {
        switch viewAction {
        case .loadEvent:
            fetchEvent(eventId: eventId)
        case .close:
            actionsSubject.send(.close)
        case .showColorPicker:
            state.isColorPickerShown = true
        case .hideColorPicker:
            state.isColorPickerShown = false
        }
    }
    
    // MARK: - Private Helpers
    
    private func createColorPickerBinding(for event: Response.Event) -> Binding<Color> {
        Binding<Color>(
            get: { [weak self] in
                self?.state.bindings.colorPickerLocalSelection ?? .clear
            },
            set: { [weak self] newColor in
                guard let self = self else { return }
                self.state.bindings.colorPickerLocalSelection = newColor
                
                let hex = newColor.toHexString()
                self.colorUpdateSubject.send((courseId: event.courseId, hex: hex))
                
                if case .loaded(let currentEvent) = self.state.dataState {
                    let locallyUpdated = currentEvent.withUpdatedColor(hex)
                    self.state.dataState = .loaded(event: locallyUpdated)
                }
            }
        )
    }
}

