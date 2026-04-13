//
//  AccountSettingsScreenCoordinator.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

enum AccountSettingsScreenCoordinatorAction {
    case accountAdded(TumbleUser)
    case dismiss
}

struct AccountSettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
    let authenticationService: AuthenticationServiceProtocol
}

final class AccountSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AccountSettingsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<AccountSettingsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AccountSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: AccountSettingsScreenCoordinatorParameters) {
        viewModel = AccountSettingsScreenViewModel(
            appSettings: parameters.appSettings,
            authenticationService: parameters.authenticationService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                self?.handleViewModelAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func handleViewModelAction(_ action: AccountSettingsScreenViewModelAction) {
        switch action {
        case .loginSuccessful(let user):
            actionsSubject.send(.accountAdded(user))
        case .loginFailed:
            break // Handled in view
        }
    }
            
    func toPresentable() -> AnyView {
        AnyView(AccountSettingsScreen(context: viewModel.context))
    }
}
