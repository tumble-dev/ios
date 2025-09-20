//
//  AuthFlowCoordinator.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI

enum AccountFlowCoordinatorAction {
    case presentedAccount
    case dismissedAccount
}

struct AccountFlowCoordinatorParameters {
    let windowManager: WindowManagerProtocol
    let appSettings: AppSettings
    let keychainService: KeychainService
    let tumbleApiService: TumbleAPIService
    let eventStorageService: EventStorageService
    let analyticsService: AnalyticsServiceProtocol
    let navigationSplitCoordinator: NavigationSplitCoordinator
}

class AccountFlowCoordinator: FlowCoordinatorProtocol {
    private let parameters: AccountFlowCoordinatorParameters
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<AccountFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AccountFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AccountFlowCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func start() {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .account:
            presentAccountScreen(animated: animated)
        default:
            break
        }
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
    
    // MARK: - Private
    
    private func presentAccountScreen(animated: Bool) {
        navigationStackCoordinator = NavigationStackCoordinator()

        let accountScreenCoordinator = AccountScreenCoordinator(
            parameters: .init(
                tumbleApiService: parameters.tumbleApiService,
                analyticsService: parameters.analyticsService,
                appSettings: parameters.appSettings,
                keychainService: parameters.keychainService
            )
        )
        
        accountScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .resourcesScreen:
                    break
                case .eventsScreen:
                    break
                case .resourceBookingDetails:
                    break
                case .eventDetails:
                    break
                case .dismiss:
                    parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                }
                
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(accountScreenCoordinator, animated: animated)
        
        parameters.navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            // notify BookmarksFlowCoordinator to properly set state
            actionsSubject.send(.dismissedAccount)
        }
        
        // notify BookmarksFlowCoordinator to properly set state
        actionsSubject.send(.presentedAccount)
    }
    
    // MARK: - Navigation Methods
    
}
