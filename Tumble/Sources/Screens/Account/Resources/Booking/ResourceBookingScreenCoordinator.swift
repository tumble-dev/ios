//
//  ResourceBookingScreenCoordinator.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-02.
//

import Combine
import SwiftUI

struct ResourceBookingScreenCoordinatorParameters {
    let tumbleApiService: TumbleApiServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    let authenticationService: AuthenticationServiceProtocol
    let appSettings: AppSettings
    let resource: Response.Resource
    let selectedPickerDate: Date
}

enum ResourceBookingScreenCoordinatorAction {
    case pop
    case pushResourceTimeslotSelectionScreen(Response.Resource, Date)
}

final class ResourceBookingScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ResourceBookingScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<ResourceBookingScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<ResourceBookingScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    
    init(parameters: ResourceBookingScreenCoordinatorParameters) {
        viewModel = ResourceBookingScreenViewModel(
            appSettings: parameters.appSettings,
            tumbleApiService: parameters.tumbleApiService,
            analyticsService: parameters.analyticsService,
            authenticationService: parameters.authenticationService,
            resource: parameters.resource,
            selectedPickerDate: parameters.selectedPickerDate
        )
        
        viewModel.actions
            .sink { action in
                switch action {
                case .bookingSuccess:
                    // Handle successful booking if needed
                    // For example, you could show a toast or update parent coordinator
                    break
                case .bookingFailed(let errorMessage):
                    // Handle booking failure if needed
                    // Error is already shown in the UI via alerts
                    AppLogger.shared.error("Resource booking failed: \(errorMessage)")
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(ResourceBookingScreen(context: viewModel.context))
    }
}
