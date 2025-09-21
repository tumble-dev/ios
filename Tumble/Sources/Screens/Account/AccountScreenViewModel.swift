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
            AppLogger.shared.info("Using token \(token)")
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
    
    private func fetchUserBookings(from school: String) async throws -> [Response.Booking] {
        do {
            let token = try await authenticationService.getCurrentSessionToken()
            AppLogger.shared.info("Using token \(token)")
            return try await tumbleApiService.getUserBookings(school: school, authToken: token)
        } catch NetworkError.unauthorized {
            try await authenticationService.autoReLogin()
            let newToken = try await authenticationService.getCurrentSessionToken()
            return try await tumbleApiService.getUserBookings(school: school, authToken: newToken)
        }
    }
    
    private func setupListeners() {
        appSettings.$activeUsername
            .sink { [weak self] username in
                guard let self else { return }
                guard let username else {
                    state.userState = .missing
                    return
                }
                Task { await self.loadActiveUser(username: username) }
            }
            .store(in: &cancellables)
    }
    
    private func loadActiveUser(username: String) async {
        await MainActor.run {
            state.userState = .loading
        }
        let user = userDataStorageService.getUserProfile(username: username)
        guard let user else {
            await MainActor.run {
                state.userState = .error("Could not get user \(username)")
            }
            return
        }
        await MainActor.run {
            state.userState = .loaded(user: user)
        }
        AppLogger.shared.info("[AccountScreenViewModel] Loaded user \(user.username)")
        await loadUserData(from: user.school)
    }
}
