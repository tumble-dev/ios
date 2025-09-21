//
//  OnboardingFlowCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import UIKit
import SwiftState

class OnboardingFlowCoordinator: FlowCoordinatorProtocol {
    
    private var cancellables = Set<AnyCancellable>()
    private let stateMachine: StateMachine<State, Event>
    
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsServiceProtocol
    private let notificationManager: NotificationManagerProtocol
    private let isFirstOpen: Bool
    

    private let rootNavigationStackCoordinator: NavigationStackCoordinator
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    init(
        appSettings: AppSettings,
        analyticsService: AnalyticsServiceProtocol,
        notificationManager: NotificationManagerProtocol,
        isFirstOpen: Bool,
        rootNavigationStackCoordinator: NavigationStackCoordinator
    ) {
        self.rootNavigationStackCoordinator = rootNavigationStackCoordinator
        self.navigationStackCoordinator = NavigationStackCoordinator()
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.notificationManager = notificationManager
        self.isFirstOpen = isFirstOpen
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    enum State: StateType {
        case initial
        case notificationPermissions
        case finished
    }
    
    enum Event: EventType {
        case next
    }
    
    func start() {
        guard shouldStart else {
            fatalError("This flow coordinator shouldn't have been started")
        }
        
        rootNavigationStackCoordinator.setFullScreenCoverCoordinator(navigationStackCoordinator, animated: !isFirstOpen)
        stateMachine.tryEvent(.next)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    var shouldStart: Bool {
        return isFirstOpen
    }
    
    // MARK: - Private
    
    private var requiresNotificationsSetup: Bool {
        !appSettings.hasRunNotificationPermissionsOnboarding
    }
}

// MARK: - Configuration

private extension OnboardingFlowCoordinator {
    // MARK: - Setup
    private func configureStateMachine() {
        stateMachine.addRoute(.init(fromState: .finished, toState: .initial))
        stateMachine.addRouteMapping { [weak self] event, fromState, _ in
            guard let self else {
                return nil
            }
            
            switch (fromState, requiresNotificationsSetup) {
            case (.initial, true):
                return .notificationPermissions
            case (.initial, false):
                return .finished
            case (.notificationPermissions, _):
                return .finished
            default:
                return nil
            }
        }

        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            
            case (_, _, .notificationPermissions):
                presentNotificationPermissionsScreen()
            case (_, _, .finished):
                rootNavigationStackCoordinator.setFullScreenCoverCoordinator(nil)
                stateMachine.tryState(.initial)
            case (.finished, _, .initial):
                break
            default:
                fatalError("Unknown transition: \(context)")
            }
            
            if let event = context.event {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)`")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentCoordinator(_ coordinator: CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        if navigationStackCoordinator.rootCoordinator == nil {
            navigationStackCoordinator.setRootCoordinator(coordinator, dismissalCallback: dismissalCallback)
        } else {
            navigationStackCoordinator.push(coordinator, dismissalCallback: dismissalCallback)
        }
    }
}

// MARK: - Screens

private extension OnboardingFlowCoordinator {
    
    private func presentNotificationPermissionsScreen() {
        let coordinator = NotificationPermissionsScreenCoordinator(parameters: .init(notificationManager: notificationManager))
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .done:
                    appSettings.hasRunNotificationPermissionsOnboarding = true
                    stateMachine.tryEvent(.next)
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
}
