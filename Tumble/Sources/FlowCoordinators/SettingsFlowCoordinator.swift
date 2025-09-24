//
//  SettingsFlowCoordinator.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI

enum SettingsFlowCoordinatorAction {
    case presentedSettings
    case dismissedSettings
}

struct SettingsFlowCoordinatorParameters {
    let windowManager: WindowManagerProtocol
    let appSettings: AppSettings
    let eventStorageService: EventStorageServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    let authenticationService: AuthenticationServiceProtocol
    let navigationSplitCoordinator: NavigationSplitCoordinator
}

class SettingsFlowCoordinator: FlowCoordinatorProtocol {
    private let parameters: SettingsFlowCoordinatorParameters
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SettingsFlowCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func start() {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .settings:
            presentSettingsScreen(animated: animated)
        case .settingsDetails:
            break // TODO: Implement routing to specific setting
        default:
            break
        }
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
    
    // MARK: - Private
    
    private func presentSettingsScreen(animated: Bool) {
        navigationStackCoordinator = NavigationStackCoordinator()
        
        let settingsScreenCoordinator = SettingsScreenCoordinator(
            parameters: .init(
                appSettings: parameters.appSettings,
                analyticsService: parameters.analyticsService,
                authenticationService: parameters.authenticationService
            )
        )
        
        settingsScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                    
                case .notifications:
                    presentNotificationSettings()
                    
                case .advancedSettings:
                    presentAdvancedSettings()
                    
                case .addAccount:
                    presentAddAccountScreen()
                    
                case .removeAccount:
                    break // TODO: Use authflowcoordinator
                    
                case .language:
                    presentLanguageSettings()
                    
                case .help:
                    presentHelpAndSupport()
                    
                case .sendFeedback:
                    presentFeedbackScreen()
                    
                case .about:
                    presentAboutScreen()
                    
                case .bookmarkedProgrammes:
                    presentBookmarksSettings()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
        
        parameters.navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            // notify BookmarksFlowCoordinator to properly set state
            actionsSubject.send(.dismissedSettings)
        }
        
        // notify BookmarksFlowCoordinator to properly set state
        actionsSubject.send(.presentedSettings)
    }
    
    // MARK: - Navigation Methods
    
    private func presentAdvancedSettings() {
        let coordinator = AdvancedSettingsScreenCoordinator(
            parameters: .init(
                appSettings: parameters.appSettings,
                analyticsService: parameters.analyticsService
            )
        )
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentNotificationSettings() {
        let coordinator = NotificationsSettingsScreenCoordinator(
            parameters: .init(
                appSettings: parameters.appSettings
            )
        )
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentBookmarksSettings() {
        let coordinator = BookmarksSettingsScreenCoordinator(
            parameters: .init(
                appSettings: parameters.appSettings,
                eventStorageService: parameters.eventStorageService
            )
        )
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .dismiss:
                    navigationStackCoordinator.pop(animated: true)
                }
            }.store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentAddAccountScreen() {
        let coordinator = AccountSettingsScreenCoordinator(
            parameters: .init(
                appSettings: parameters.appSettings,
                authenticationService: parameters.authenticationService
            )
        )
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                default:
                    navigationStackCoordinator.popToRoot()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentLanguageSettings() {
        // TODO: Create LanguageSettingsScreenCoordinator
        // let coordinator = LanguageSettingsScreenCoordinator(parameters: .init(appSettings: parameters.appSettings))
        // navigationStackCoordinator.push(coordinator)
        
        AppLogger.shared.info("Navigate to Language Settings")
    }
    
    private func presentHelpAndSupport() {
        // TODO: Create HelpAndSupportScreenCoordinator or open external URL
        // let coordinator = HelpAndSupportScreenCoordinator()
        // navigationStackCoordinator.push(coordinator)
        
        // Or open external help URL
        if let url = URL(string: "https://tumbleforkronox.com/help") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
        
        AppLogger.shared.info("Navigate to Help & Support")
    }
    
    private func presentFeedbackScreen() {
        // TODO: Create FeedbackScreenCoordinator or open mail composer
        // let coordinator = FeedbackScreenCoordinator()
        // navigationStackCoordinator.push(coordinator)
        
        // Or open mail composer
        openMailComposer()
        
        AppLogger.shared.info("Navigate to Send Feedback")
    }
    
    private func presentAboutScreen() {
        // TODO: Create AboutScreenCoordinator
        // let coordinator = AboutScreenCoordinator(parameters: .init(appSettings: parameters.appSettings))
        // navigationStackCoordinator.push(coordinator)
        
        AppLogger.shared.info("Navigate to About Screen")
    }
    
    // MARK: - Helper Methods
    
    private func openMailComposer() {
        let mailtoString = "mailto:support@tumbleforkronox.com?subject=App%20Feedback&body=Hello,%0A%0AI%20have%20feedback%20about%20your%20app:%0A%0A"
        
        if let mailtoUrl = URL(string: mailtoString) {
            DispatchQueue.main.async {
                UIApplication.shared.open(mailtoUrl)
            }
        }
    }
}
