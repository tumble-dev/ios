//
//  EventDetailsScreenCoordinator.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI
import Combine
import Foundation

struct EventDetailsScreenCoordinatorParameters {
    let eventId: String
    let appSettings: AppSettings
    let eventStorageService: EventStorageService
    let notificationManager: NotificationManagerProtocol
}

enum EventDetailsScreenCoordinatorAction {
    case dismiss
}

final class EventDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: EventDetailsScreenViewModel
    private let actionsSubject: PassthroughSubject<EventDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<EventDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EventDetailsScreenCoordinatorParameters) {
        viewModel = EventDetailsScreenViewModel(
            eventId: parameters.eventId,
            appSettings: parameters.appSettings,
            eventStorageService: parameters.eventStorageService,
            notificationManager: parameters.notificationManager
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .close:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func start() {
    }
        
    func toPresentable() -> AnyView {
        AnyView(EventDetailsScreen(context: viewModel.context))
    }
}
