//
//  AccountScreenCoordinator.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

struct AccountScreenCoordinatorParameters {
    let tumbleApiService: TumbleApiServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    let userDataStorageService: UserDataStorageServiceProtocol
    let authenticationService: AuthenticationServiceProtocol
    let appSettings: AppSettings
}

enum AccountScreenCoordinatorAction {
    case resourceSelectionScreen
    case resourceBookingDetails(Response.Booking)
    case dismiss
}

final class AccountScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AccountScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<AccountScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AccountScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    
    init(parameters: AccountScreenCoordinatorParameters) {
        viewModel = AccountScreenViewModel(
            appSettings: parameters.appSettings,
            tumbleApiService: parameters.tumbleApiService,
            userDataStorageService: parameters.userDataStorageService,
            analyticsService: parameters.analyticsService,
            authenticationService: parameters.authenticationService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .resourceSelectionScreen:
                    actionsSubject.send(.resourceSelectionScreen)
                case .resourceBookingDetails(let booking):
                    actionsSubject.send(.resourceBookingDetails(booking))
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func refreshBookings() {
        viewModel.context.send(viewAction: .refreshBookings)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AccountScreen(context: viewModel.context))
    }
}
