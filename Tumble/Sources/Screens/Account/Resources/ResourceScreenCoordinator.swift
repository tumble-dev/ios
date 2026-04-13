//
//  ResourceScreenCoordinator.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-10-30.
//

import Combine
import SwiftUI

struct ResourceSelectionScreenCoordinatorParameters {
    let tumbleApiService: TumbleApiServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    let authenticationService: AuthenticationServiceProtocol
    let appSettings: AppSettings
}

enum ResourceSelectionScreenCoordinatorAction {
    case pop
    case pushResourceTimeslotSelectionScreen(Response.Resource, Date)
}

final class ResourceSelectionScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ResourceSelectionScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<ResourceSelectionScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<ResourceSelectionScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    
    init(parameters: ResourceSelectionScreenCoordinatorParameters) {
        viewModel = ResourceSelectionScreenViewModel(
            appSettings: parameters.appSettings,
            tumbleApiService: parameters.tumbleApiService,
            analyticsService: parameters.analyticsService,
            authenticationService: parameters.authenticationService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .pushResourceTimeslotSelectionScreen(let resource, let date):
                    actionsSubject.send(.pushResourceTimeslotSelectionScreen(resource, date))
                case .pop:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(ResourceSelectionScreen(context: viewModel.context))
    }
}
