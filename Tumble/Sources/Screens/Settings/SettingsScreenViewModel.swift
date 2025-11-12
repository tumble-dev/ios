//
//  SettingsScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI

typealias SettingsScreenViewModelType = StateStoreViewModel<SettingsScreenViewState, SettingsScreenViewAction>

class SettingsScreenViewModel: SettingsScreenViewModelType, SettingsScreenViewModelProtocol {
    private let quickSettings: SettingsProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    
    private var actionsSubject: PassthroughSubject<SettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    func setupObservers() {
        guard let appSettings = quickSettings as? AppSettings else { return }
        
        let publishers = [
            appSettings.$appearance.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$bookmarkedProgrammes.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$activeUsername.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$openEventFromWidget.map { _ in () }.eraseToAnyPublisher()
        ]
        
        Publishers.MergeMany(publishers)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.state.bindings = SettingsScreenViewStateBindings(
                    quickSettings: self.quickSettings,
                    authenticationService: self.authenticationService,
                    onActiveUsernameChange: { [weak self] newUsername in
                        self?.handleActiveUserChange(newUsername)
                    }
                )
            }
            .store(in: &cancellables)
        
        authenticationService.authStatePublisher
            .sink { [weak self] authState in
                guard let self else { return }
                AppLogger.shared.debug("SettingsScreenViewModel: Received auth state update via publisher: \(authState)")
                state.authState = authState
            }
            .store(in: &cancellables)
    }

    init(
        quickSettings: SettingsProtocol,
        analyticsService: AnalyticsServiceProtocol,
        authenticationService: AuthenticationServiceProtocol
    ) {
        self.analyticsService = analyticsService
        self.quickSettings = quickSettings
        self.authenticationService = authenticationService
        
        let initialState = SettingsScreenViewState(
            bindings: .init(
                quickSettings: quickSettings,
                authenticationService: authenticationService,
                onActiveUsernameChange: nil
            )
        )
        super.init(initialViewState: initialState)
        
        setupObservers()
    }
    
    override func process(viewAction: SettingsScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .removeAccount:
            handleRemoveAccount()
        case .addAccount:
            actionsSubject.send(.addAccount)
        case .notifications:
            actionsSubject.send(.notifications)
        case .advancedSettings:
            actionsSubject.send(.advancedSettings)
        case .language:
            actionsSubject.send(.language)
        case .help:
            actionsSubject.send(.help)
        case .rateApp:
            handleRateApp()
        case .sendFeedback:
            actionsSubject.send(.sendFeedback)
        case .about:
            actionsSubject.send(.about)
        case .bookmarkedProgrammes:
            actionsSubject.send(.bookmarkedProgrammes)
        case .switchAccount(let username):
            switchToAccount(username)
        case .showAccountPicker:
            state.showingAccountPicker = true
        }
    }
    
    private func handleActiveUserChange(_ newUsername: String) {
        // Don't update the setting immediately - let the switch operation handle it
        Task {
            do {
                _ = try await authenticationService.switchToUser(username: newUsername)
                // The authenticationService will update the activeUsername through its state management
            } catch {
                AppLogger.shared.error("Failed to switch to user: \(error)")
                // Optionally show an error to the user
            }
        }
    }
    
    private func switchToAccount(_ username: String) {
        Task {
            do {
                _ = try await authenticationService.switchToUser(username: username)
            } catch {
                AppLogger.shared.error("Failed to switch account: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleRateApp() {
        // Open App Store rating
        guard let url = URL(string: "https://apps.apple.com/app/1617642864?action=write-review") else {
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    private func handleRemoveAccount() {
        AppLogger.shared.debug("SettingsScreenViewModel: handleRemoveAccount started")
        Task {
            do {
                if let currentUser = authenticationService.getCurrentUser() {
                    AppLogger.shared.debug("SettingsScreenViewModel: Removing user: \(currentUser.username)")
                    let remainingAccounts = try await authenticationService.removeAccount(username: currentUser.username)
                    AppLogger.shared.info("Available remaining accounts: \(remainingAccounts) ")
                    
                    // Force a UI refresh after account removal
                    await MainActor.run {
                        AppLogger.shared.debug("SettingsScreenViewModel: Forcing UI refresh after account removal")
                        let currentAuthState = authenticationService.getCurrentAuthState()
                        AppLogger.shared.debug("SettingsScreenViewModel: Current auth state after removal: \(currentAuthState)")
                        
                        self.state.authState = currentAuthState
                        self.state.bindings = SettingsScreenViewStateBindings(
                            quickSettings: self.quickSettings,
                            authenticationService: self.authenticationService,
                            onActiveUsernameChange: { [weak self] newUsername in
                                self?.handleActiveUserChange(newUsername)
                            }
                        )
                        
                        AppLogger.shared.debug("SettingsScreenViewModel: UI refresh completed")
                        actionsSubject.send(.removeAccount)
                    }
                }
            } catch {
                AppLogger.shared.error("Failed to remove account: \(error)")
            }
        }
    }
}
