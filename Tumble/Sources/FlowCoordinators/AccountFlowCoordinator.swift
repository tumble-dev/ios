//
//  AccountFlowCoordinator.swift
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
    let tumbleApiService: TumbleApiServiceProtocol
    let eventStorageService: EventStorageServiceProtocol
    let userDataStorageService: UserDataStorageServiceProtocol
    let authenticationService: AuthenticationServiceProtocol
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
        
        // Configure presentation detents to make the sheet initially smaller
        if #available(iOS 16.0, *) {
            navigationStackCoordinator.setPresentationDetents([
                .fraction(0.4),
                .medium,
                .large
            ])
        }

        let accountScreenCoordinator = AccountScreenCoordinator(
            parameters: .init(
                tumbleApiService: parameters.tumbleApiService,
                analyticsService: parameters.analyticsService,
                userDataStorageService: parameters.userDataStorageService,
                authenticationService: parameters.authenticationService,
                appSettings: parameters.appSettings
            )
        )
        
        accountScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .resourceSelectionScreen:
                    presentResourceSelectionScreen(animated: true)
                case .resourceBookingDetails(let booking):
                    presentBookingDetailsScreen(booking: booking)
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
    
    func presentResourceSelectionScreen(animated: Bool) {
        let coordinator = ResourceSelectionScreenCoordinator(
            parameters: .init(
                tumbleApiService: parameters.tumbleApiService,
                analyticsService: parameters.analyticsService,
                authenticationService: parameters.authenticationService,
                appSettings: parameters.appSettings
            )
        )
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .pop:
                navigationStackCoordinator.pop()
            case .pushResourceTimeslotSelectionScreen(let resource, let date):
                presentResourceTimeSlotSelectionScreen(resource: resource, selectedPickerDate: date)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentResourceTimeSlotSelectionScreen(resource: Response.Resource, selectedPickerDate: Date) {
        let coordinator = ResourceBookingScreenCoordinator(
            parameters: .init(
                tumbleApiService: parameters.tumbleApiService,
                analyticsService: parameters.analyticsService,
                authenticationService: parameters.authenticationService,
                appSettings: parameters.appSettings,
                resource: resource,
                selectedPickerDate: selectedPickerDate
            )
        )
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentBookingDetailsScreen(booking: Response.Booking) {
        let coordinator = BookingDetailsScreenCoordinator(
            parameters: .init(
                booking: booking,
                school: "hkr",
                tumbleApiService: parameters.tumbleApiService,
                authenticationService: parameters.authenticationService
            )
        )
        
        navigationStackCoordinator.push(coordinator)
    }
}
