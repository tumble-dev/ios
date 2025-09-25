//
//  AnalyticsPermissionsScreenCoordinator.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-25.
//


import Combine
import SwiftUI

struct AnalyticsPermissionsScreenCoordinatorParameters {
    let appSettings: AppSettings
}

enum AnalyticsPermissionsScreenCoordinatorAction {
    case next
}

final class AnalyticsPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AnalyticsPermissionsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AnalyticsPermissionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AnalyticsPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AnalyticsPermissionsScreenCoordinatorParameters) {
        viewModel = AnalyticsPermissionsScreenViewModel(appSettings: parameters.appSettings)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    actionsSubject.send(.next)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AnalyticsPermissionsScreen(context: viewModel.context))
    }
}
