//
//  SettingsScreenViewModel.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI

typealias SettingsScreenViewModelType = StateStoreViewModel<SettingsScreenViewState, SettingsScreenViewAction>

class SettingsScreenViewModel: SettingsScreenViewModelType, SettingsScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsServiceProtocol
    
    private var actionsSubject: PassthroughSubject<SettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appSettings: AppSettings, analyticsService: AnalyticsServiceProtocol) {
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        
        let userDisplayName: String? = {
            guard let userId = appSettings.activeUser else { return nil }
            return userId.capitalized
        }()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        let initialState = SettingsScreenViewState(
            userId: appSettings.activeUser,
            userDisplayName: userDisplayName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            bookmarkedProgrammesCount: appSettings.savedProgrammeIds.count
        )
        
        super.init(initialViewState: initialState)
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
        case .appearance:
            actionsSubject.send(.appearance)
        case .language:
            actionsSubject.send(.language)
        case .privacy:
            actionsSubject.send(.privacy)
        case .security:
            actionsSubject.send(.security)
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
        case .widget:
            actionsSubject.send(.widget)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleRemoveAccount() {
        // Clear user-related settings
        appSettings.activeUser = nil
        
        // Update view state
        state.userId = nil
        state.userDisplayName = nil
        
        actionsSubject.send(.removeAccount)
    }
    
    private func handleRateApp() {
        // Open App Store rating
        guard let url = URL(string: "https://apps.apple.com/app/1617642864?action=write-review") else {
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}
