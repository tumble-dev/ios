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
    private var accountScreenCoordinator: AccountScreenCoordinator?
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
        case .bookingDetails(let bookingId):
            presentAccountScreenWithBookingDetails(bookingId: bookingId, animated: animated)
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
        
        // Store reference to the coordinator so we can refresh it later
        self.accountScreenCoordinator = accountScreenCoordinator
        
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
    
    private func presentAccountScreenWithBookingDetails(bookingId: String, animated: Bool) {
        presentAccountScreen(animated: animated)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            await navigateToBookingDetails(bookingId: bookingId)
        }
    }
    
    private func navigateToBookingDetails(bookingId: String) async {
        do {
            AppLogger.shared.info("[AccountFlowCoordinator] Navigating to booking details for ID: \(bookingId)")
            
            let token = try await parameters.authenticationService.getCurrentSessionToken()
            let userSchool = try getCurrentUserSchool()
            
            let bookings = try await parameters.tumbleApiService.getUserBookings(school: userSchool, authToken: token)
            
            guard let booking = bookings.first(where: { $0.id == bookingId }) else {
                AppLogger.shared.warning("[AccountFlowCoordinator] Booking with ID \(bookingId) not found in user bookings")
                return
            }
            
            presentBookingDetailsScreen(booking: booking)
            
        } catch {
            AppLogger.shared.error("[AccountFlowCoordinator] Failed to navigate to booking details: \(error)")
        }
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
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .pop:
                    navigationStackCoordinator.pop(animated: true)
                case .pushResourceTimeslotSelectionScreen(let resource, let date):
                    presentResourceTimeSlotSelectionScreen(resource: resource, selectedPickerDate: date)
                case .bookingMade:
                    AppLogger.shared.info("[AccountFlowCoordinator] New booking was made, refreshing account screen")
                    accountScreenCoordinator?.refreshBookings()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentBookingDetailsScreen(booking: Response.Booking) {
        do {
            let userSchool = try getCurrentUserSchool()
            
            let coordinator = BookingDetailsScreenCoordinator(
                parameters: .init(
                    booking: booking,
                    school: userSchool,
                    tumbleApiService: parameters.tumbleApiService,
                    authenticationService: parameters.authenticationService
                )
            )
            
            // Subscribe to the coordinator's actions to handle dismissal
            coordinator.actions
                .sink { [weak self] action in
                    guard let self else { return }
                    switch action {
                    case .dismiss:
                        // Pop the booking details screen to return to account screen
                        navigationStackCoordinator.pop(animated: true)
                    case .bookingUpdated:
                        // Refresh the account screen to remove the cancelled booking from the list
                        AppLogger.shared.info("[AccountFlowCoordinator] Booking was updated, refreshing account screen")
                        accountScreenCoordinator?.refreshBookings()
                    }
                }
                .store(in: &cancellables)
            
            navigationStackCoordinator.push(coordinator)
        } catch BookingError.noAuthenticatedUser {
            AppLogger.shared.error("[AccountFlowCoordinator] Cannot present booking details: No authenticated user")
            // Could show an alert or handle this case appropriately
            // For now, we'll just log the error and not navigate
        } catch {
            AppLogger.shared.error("[AccountFlowCoordinator] Unexpected error getting user school: \(error)")
        }
    }
    
    /// Helper method to get the current user's school from the authentication service
    /// - Throws: BookingError.noAuthenticatedUser if no user is authenticated
    private func getCurrentUserSchool() throws -> String {
        guard let currentUser = parameters.authenticationService.getCurrentUser() else {
            AppLogger.shared.error("[AccountFlowCoordinator] No authenticated user found for booking operation")
            throw BookingError.noAuthenticatedUser
        }
        
        AppLogger.shared.debug("[AccountFlowCoordinator] Retrieved user school: \(currentUser.school) for user: \(currentUser.username)")
        return currentUser.school
    }
}
