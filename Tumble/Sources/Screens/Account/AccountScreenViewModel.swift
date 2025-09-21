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
            break
        case .showEvents:
            break
        case .showResourceBookingDetails:
            break
        case .showEventDetails:
            break
        }
    }
    
    private func loadUserData(from school: String) async {
        do {
            let bookings = try await fetchUserBookings(from: school)
            let registeredEvents = try await fetchUserRegisteredEvents(from: school)
            updateDataState(newState: .loaded(events: registeredEvents, bookings: bookings))
        } catch {
            updateDataState(newState: .error(error.localizedDescription))
            return
        }
    }
    
    private func fetchUserRegisteredEvents(from school: String) async throws -> [Response.UserEvent] {
        do {
            let token = try await authenticationService.getCurrentSessionToken()
            return try await tumbleApiService.getRegisteredEvents(school: school, authToken: token)
        } catch NetworkError.unauthorized {
            try await authenticationService.autoReLogin()
            let newToken = try await authenticationService.getCurrentSessionToken()
            return try await tumbleApiService.getRegisteredEvents(school: school, authToken: newToken)
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
    
    private func fetchUserBookings(from school: String) async throws -> [Response.Booking] {
        do {
            let token = try await authenticationService.getCurrentSessionToken()
            return try await tumbleApiService.getUserBookings(school: school, authToken: token)
        } catch NetworkError.unauthorized {
            try await authenticationService.autoReLogin()
            let newToken = try await authenticationService.getCurrentSessionToken()
            return try await tumbleApiService.getUserBookings(school: school, authToken: newToken)
        }
    }
    
    private func setupListeners() {
        authenticationService.authStatePublisher
            .sink { [weak self] authState in
                guard let self = self else { return }
                AppLogger.shared.info("Got state: \(authState)")
                switch authState {
                case .authenticated(let user):
                    updateUserState(newState: .loaded(user: user))
                    Task { await self.loadUserData(from: user.school) }
                case .unauthenticated:
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
