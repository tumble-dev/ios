//
//  SettingsScreenCoordinatorParameters.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI

struct SettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
    let analyticsService: AnalyticsServiceProtocol
}

enum SettingsScreenCoordinatorAction {
    case dismiss
    case removeAccount
    case addAccount
    case notifications
    case advancedSettings
    case appearance
    case language
    case help
    case sendFeedback
    case about
    case bookmarkedProgrammes
    case widget
}

final class SettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SettingsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<SettingsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    
    init(parameters: SettingsScreenCoordinatorParameters) {
        viewModel = SettingsScreenViewModel(
            appSettings: parameters.appSettings,
            analyticsService: parameters.analyticsService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .close:
                    actionsSubject.send(.dismiss)
                case .notifications:
                    actionsSubject.send(.notifications)
                case .advancedSettings:
                    actionsSubject.send(.advancedSettings)
                case .removeAccount:
                    actionsSubject.send(.removeAccount)
                case .addAccount:
                    actionsSubject.send(.addAccount)
                case .appearance:
                    actionsSubject.send(.appearance)
                case .language:
                    actionsSubject.send(.language)
                case .help:
                    actionsSubject.send(.help)
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
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SettingsScreen(context: viewModel.context))
    }
}
