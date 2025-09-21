//
//  NotificationsSettingsScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

typealias NotificationsSettingsScreenViewModelType = StateStoreViewModel<NotificationsSettingsScreenViewState, NotificationsSettingsScreenViewAction>

class NotificationsSettingsScreenViewModel: NotificationsSettingsScreenViewModelType, NotificationsSettingsScreenViewModelProtocol {
    private let notificationsSettings: NotificationsSettingsProtocol
    
    init(notificationsSettings: NotificationsSettingsProtocol) {
        self.notificationsSettings = notificationsSettings
        let state = NotificationsSettingsScreenViewState(bindings: .init(notificationsSettings: notificationsSettings))
        super.init(initialViewState: state)
        
        setupObservers()
    }
    
    override func process(viewAction: NotificationsSettingsScreenViewAction) {
        switch viewAction {
        case .resetAllSettings:
            handleResetAllSettings()
        }
    }
    
    func setupObservers() {
        guard let appSettings = notificationsSettings as? AppSettings else { return }
        
        let publishers = [
            appSettings.$notificationOffset.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$inAppMessagingEnabled.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$notificationsEnabled.map { _ in () }.eraseToAnyPublisher(),
        ]
        
        Publishers.MergeMany(publishers)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.state.bindings = NotificationsSettingsScreenViewStateBindings(notificationsSettings: self.notificationsSettings)
            }
            .store(in: &cancellables)
    }
    
    private func handleResetAllSettings() {
        notificationsSettings.resetNotificationsSettings()
    }
}
