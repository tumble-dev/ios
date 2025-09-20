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
    private let tumbleApiService: TumbleAPIService
    private let keychainService: KeychainService
    private let analyticsService: AnalyticsServiceProtocol
    
    private var actionsSubject: PassthroughSubject<AccountScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AccountScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        tumbleApiService: TumbleAPIService,
        keychainService: KeychainService,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.analyticsService = analyticsService
        self.tumbleApiService = tumbleApiService
        self.keychainService = keychainService
        self.appSettings = appSettings
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
        let user = await keychainService.getTumbleUser(byUsername: username)
        guard let user else {
            // TODO: If this happens, we need to attempt to remove the user
            // from the keychain, and set the activeUser in AppSettings to any
            // available keychain item != this one and reload the screen
            await MainActor.run {
                state.userState = .error("Could not get user \(username)")
            }
            return
        }
        await MainActor.run {
            state.userState = .loaded(user: user)
        }
    }
}
