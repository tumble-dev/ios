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
}

enum NotificationPermissionsScreenCoordinatorAction {
    case done
}

final class NotificationPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: NotificationPermissionsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationPermissionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<NotificationPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationPermissionsScreenCoordinatorParameters) {
        viewModel = NotificationPermissionsScreenViewModel(notificationManager: parameters.notificationManager)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    actionsSubject.send(.done)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationPermissionsScreen(context: viewModel.context))
    }
}
