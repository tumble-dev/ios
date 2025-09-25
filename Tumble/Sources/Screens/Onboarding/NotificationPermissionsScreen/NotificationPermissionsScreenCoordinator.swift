//
//  NotificationPermissionsScreenCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import SwiftUI

struct NotificationPermissionsScreenCoordinatorParameters {
    let notificationManager: NotificationManagerProtocol
    let appSettings: AppSettings
}

enum NotificationPermissionsScreenCoordinatorAction {
    case next
}

final class NotificationPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: NotificationPermissionsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationPermissionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<NotificationPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationPermissionsScreenCoordinatorParameters) {
        viewModel = NotificationPermissionsScreenViewModel(
            appSettings: parameters.appSettings, notificationManager: parameters.notificationManager
        )
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .next:
                    actionsSubject.send(.next)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationPermissionsScreen(context: viewModel.context))
    }
}
