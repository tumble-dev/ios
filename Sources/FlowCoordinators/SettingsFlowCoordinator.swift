//
//  SettingsFlowCoordinator.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI

enum SettingsFlowCoordinatorAction {
    case presentedSettings
    case dismissedSettings
    case runLogoutFlow
    case runLoginFlow
    case clearCache
}

struct SettingsFlowCoordinatorParameters {
    let windowManager: WindowManagerProtocol
    let appSettings: AppSettings
    let analyticsService: AnalyticsServiceProtocol
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
        case .settingsDetails(_):
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
                analyticsService: parameters.analyticsService
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
                    actionsSubject.send(.runLoginFlow)
                    
                case .removeAccount:
                    actionsSubject.send(.runLogoutFlow)
                    
                case .appearance:
                    presentAppearanceSettings()
                    
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
                    
                case .widget:
                    presentWidgetSettings()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
        
        parameters.navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            actionsSubject.send(.dismissedSettings)
        }
        
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
                appSettings: parameters.appSettings,
            )
        )
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentAppearanceSettings() {
        // TODO: Create AppearanceSettingsScreenCoordinator
        // let coordinator = AppearanceSettingsScreenCoordinator(parameters: .init(appSettings: parameters.appSettings))
        // navigationStackCoordinator.push(coordinator)
        
        AppLogger.shared.info("Navigate to Appearance Settings")
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
        if let url = URL(string: "https://yourapp.com/help") {
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
    
    private func presentBookmarksSettings() {
        
    }
    
    private func presentWidgetSettings() { }
    
    // MARK: - Helper Methods
    
    private func openMailComposer() {
        let mailtoString = "mailto:support@yourapp.com?subject=App%20Feedback&body=Hello,%0A%0AI%20have%20feedback%20about%20your%20app:%0A%0A"
        
        if let mailtoUrl = URL(string: mailtoString) {
            DispatchQueue.main.async {
                UIApplication.shared.open(mailtoUrl)
            }
        }
    }
}
