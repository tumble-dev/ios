//
//  ApplicationCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import UIKit
import SwiftUI
import UserNotifications

class ApplicationCoordinator: ApplicationCoordinatorProtocol, NotificationManagerDelegate {
    
    let windowManager: WindowManagerProtocol
    
    private let notificationManager: NotificationManagerProtocol
    private let tumbleApiService: TumbleAPIService
    private let analyticsService: AnalyticsServiceProtocol
    private let keychainService: KeychainService
    private let eventStorageService: EventStorageService
    
    private let appDelegate: AppDelegate
    private let appMediator: AppMediator
    private let appHooks: AppHooks
    private let appSettings: AppSettings
    private var userSessionObserver: AnyCancellable?

    private var cancellables = Set<AnyCancellable>()
    private var mainFlowCoordinator: BookmarksFlowCoordinator?
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let stateMachine: ApplicationCoordinatorStateMachine
    
    private var appDelegateObserver: AnyCancellable?

    init(appDelegate: AppDelegate) {
        let appHooks = AppHooks()
        appHooks.setUp()
        
        let appSettings = appHooks.appSettingsHook.configure(AppSettings())
        
        self.windowManager = WindowManager(appDelegate: appDelegate)
        let networkMonitor = NetworkMonitor()
        appMediator = AppMediator(windowManager: windowManager, networkMonitor: networkMonitor)
        
        // MARK: - Dependencies
        self.notificationManager = NotificationManager(
            notificationCenter: UNUserNotificationCenter.current(),
            appSettings: appSettings
        )
        self.tumbleApiService = TumbleAPIService()
        self.eventStorageService = EventStorageService(appSettings: appSettings)
        self.analyticsService = AnalyticsService(appSettings: appSettings)
        self.keychainService = KeychainService(accessGroup: Config.keychainAccessGroupIdentifier)
        
        self.stateMachine = ApplicationCoordinatorStateMachine()
        self.navigationRootCoordinator = NavigationRootCoordinator()
        
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        let appName = Config.bundleDisplayName
        let appVersion = Config.bundleShortVersionString
        let appBuild = Config.bundleVersion
        AppLogger.shared.info("\(appName) \(appVersion) (\(appBuild))")
        
        self.appDelegate = appDelegate
        self.appSettings = appSettings
        self.appHooks = appHooks
        
        notificationManager.delegate = self
        notificationManager.start()
        configureNotificationManager()

        setupStateMachine()
        
        AppLogger.shared.info("[ApplicationCoordinator] Finished initializing")
    }
    
    func start() {
        guard stateMachine.state == .initial else {
            AppLogger.shared.error("Received a start request when already started")
            return
        }
        
        stateMachine.processEvent(.start)
    }

    func stop() { }
    
    func toPresentable() -> AnyView {
        AppLogger.shared.info("[ApplicationCoordinator] Calling .toPresentable()")
        return AnyView(
            navigationRootCoordinator
                .toPresentable()
                .onReceive(appSettings.$appearance) { [weak self] appearance in
                    guard let self else { return }
                    
                    windowManager.windows.forEach { window in
                        // Unfortunately .preferredColorScheme doesn't propagate properly throughout the app when changed
                        window.overrideUserInterfaceStyle = appearance.interfaceStyle
                    }
                }
        )
    }
    
    /// Initializes and starts the main coordinator flow
    func startMainFlow(isFirstOpen: Bool = false) {
        AppLogger.shared.info("[ApplicationCoordinator] Starting main application flow")
        let mainFlowCoordinator = BookmarksFlowCoordinator(
            appSettings: appSettings,
            appMediator: appMediator,
            notificationManager: notificationManager,
            tumbleApiService: tumbleApiService,
            keychainService: keychainService,
            analyticsService: analyticsService,
            eventStorageService: eventStorageService,
            navigationRootCoordinator: navigationRootCoordinator,
            isFirstOpen: isFirstOpen
        )
        
        mainFlowCoordinator.actionsPublisher
            .sink { [weak self] (action: BookmarksFlowCoordinatorAction) in
                guard let self else { return }
                
                switch action {
                case .clearCache:
                    stateMachine.processEvent(.clearCache)
                }
            }
            .store(in: &cancellables)
        mainFlowCoordinator.start()
        self.mainFlowCoordinator = mainFlowCoordinator
    }
    
    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        // TODO: Implement
        return false
    }
}


// MARK: - NotificationManagerDelegate

extension ApplicationCoordinator {
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool {
        // TODO: Implement logic to determine if notification should be shown
        // For example, check if the related screen is currently visible
        return true
    }
    
    func notificationTapped(content: UNNotificationContent) async {
        // TODO: Handle notification tap - navigate to appropriate screen
        AppLogger.shared.info("[ApplicationCoordinator] Notification tapped: \(content.title)")
        
        // Example: Extract event ID and navigate to event details
        if let eventId = content.userInfo[NotificationConstants.EventInfoKey.eventId] as? String {
            // Navigate to event with eventId
            AppLogger.shared.info("[ApplicationCoordinator] Navigating to event: \(eventId)")
        }
    }
    
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func unregisterForRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
    }
}

// MARK: - Configuration

private extension ApplicationCoordinator {
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }

            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .ready):
                Task { @MainActor [weak self] in self?.startMainFlow(isFirstOpen: true) }

            default:
                fatalError("Unknown transition: \(context)")
            }
        }
    }
    
    private func configureNotificationManager() {
        appDelegateObserver = appDelegate.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                switch callback {
                case .registeredNotifications(let deviceToken):
                    Task { await self?.notificationManager.register(with: deviceToken) }
                case .failedToRegisteredNotifications(let error):
                    self?.notificationManager.registrationFailed(with: error)
                }
            }
    }
}

