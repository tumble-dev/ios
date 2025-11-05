//
//  AccountScreenViewModel.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

typealias AccountScreenViewModelType = StateStoreViewModel<AccountScreenViewState, AccountScreenViewAction>

class AccountScreenViewModel: AccountScreenViewModelType, AccountScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let tumbleApiService: TumbleApiServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let userDataStorageService: UserDataStorageServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    private var actionsSubject: PassthroughSubject<AccountScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AccountScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        tumbleApiService: TumbleApiServiceProtocol,
        userDataStorageService: UserDataStorageServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        authenticationService: AuthenticationServiceProtocol
    ) {
        self.analyticsService = analyticsService
        self.tumbleApiService = tumbleApiService
        self.userDataStorageService = userDataStorageService
        self.appSettings = appSettings
        self.authenticationService = authenticationService
        super.init(initialViewState: .init())
        
        setupListeners()
    }
    
    override func process(viewAction: AccountScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.dismiss)
        case .showResources:
            actionsSubject.send(.resourceSelectionScreen)
        case .showResourceBookingDetails(let booking):
            actionsSubject.send(.resourceBookingDetails(booking))
        }
    }
    
    private func loadUserData(from school: String) async {
        do {
            let bookings = try await fetchUserBookings(from: school)
            updateDataState(newState: .loaded(bookings: bookings))
        } catch {
            updateDataState(newState: .error(error.localizedDescription))
            return
        }
    }

    private func fetchUserBookings(from school: String) async throws -> [Response.Booking] {
        do {
            let token = try await authenticationService.getCurrentSessionToken()
            return try await tumbleApiService.getUserBookings(school: school, authToken: token)
        } catch NetworkError.unauthorized {
            AppLogger.shared.info("Session expired while fetching bookings - WebSocket should handle re-auth")
            
            // Let the WebSocket session management handle session expiry
            // The auth state will update and trigger UI refresh through setupListeners()
            throw AuthError.sessionExpired
        } catch {
            AppLogger.shared.error("Failed to fetch user bookings: \(error)")
            throw error
        }
    }
    
    @MainActor
    private func updateDataState(newState: AccountScreenDataState) {
        state.dataState = newState
    }
    
    @MainActor
    private func updateUserState(newState: AccountScreenUserState) {
        state.userState = newState
    }
        
    private func setupListeners() {
        authenticationService.authStatePublisher
            .sink { [weak self] authState in
                guard let self = self else { return }
                switch authState {
                case .connected(let user):
                    updateUserState(newState: .loaded(user: user))
                    Task { await self.loadUserData(from: user.school) }
                case .disconnected:
                    updateUserState(newState: .missing)
                case .error(let message):
                    updateUserState(newState: .error(message))
                case .loading:
                    updateUserState(newState: .loading)
                }
            }
            .store(in: &cancellables)
    }
}
