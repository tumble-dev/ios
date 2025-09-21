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
    
    private let appSettings: AppSettings
    
    private let notificationManager: NotificationManagerProtocol
    private let keychainController: KeychainControllerProtocol
    private let authenticationService: AuthenticationServiceProtocol
    
    private let appDelegate: AppDelegate
    private let appMediator: AppMediator
    private let appHooks: AppHooks
    
    private var userSessionObserver: AnyCancellable?
    private var appDelegateObserver: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    private var mainFlowCoordinator: BookmarksFlowCoordinator?
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let stateMachine: ApplicationCoordinatorStateMachine
    

    init(appDelegate: AppDelegate) {
        let appHooks = AppHooks()
        appHooks.setUp()
        
        let appSettings = appHooks.appSettingsHook.configure(AppSettings())
        
        self.windowManager = WindowManager(appDelegate: appDelegate)
        let networkMonitor = NetworkMonitor()
        appMediator = AppMediator(windowManager: windowManager, networkMonitor: networkMonitor)
        
        // MARK: - Services, Managers & Controllers
        self.notificationManager = NotificationManager(
            notificationCenter: UNUserNotificationCenter.current(),
            appSettings: appSettings
        )
        
        Self.setupServiceLocator(appSettings: appSettings, appHooks: appHooks)
        self.keychainController = KeychainController(accessGroup: Config.keychainAccessGroupIdentifier)
        
        self.authenticationService = AuthenticationService(
            keychainController: keychainController,
            userDataStorage: ServiceLocator.shared.userDataStorageService,
            tumbleApiService: ServiceLocator.shared.tumbleApiService,
            appSettings: appSettings
        )
        
        // MARK: - Navigation & State
        
        self.stateMachine = ApplicationCoordinatorStateMachine()
        self.navigationRootCoordinator = NavigationRootCoordinator()
        
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())
        
        self.appDelegate = appDelegate
        self.appSettings = appSettings
        self.appHooks = appHooks
        
        notificationManager.delegate = self
        notificationManager.start()
        configureNotificationManager()

        setupStateMachine()
        
        AppLogger.shared.debug("[ApplicationCoordinator] Finished initializing")
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
            tumbleApiService: ServiceLocator.shared.tumbleApiService,
            analyticsService: ServiceLocator.shared.analytics,
            authenticationService: authenticationService,
            userDataStorageService: ServiceLocator.shared.userDataStorageService,
            eventStorageService: ServiceLocator.shared.eventStorageService,
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
    
    // MARK: - Private
    
    /// Register services used throughout application
    private static func setupServiceLocator(
        appSettings: AppSettings,
        appHooks: AppHooks
    ) {
        ServiceLocator.shared.register(appSettings: appSettings)
        ServiceLocator.shared.register(tumbleApiService: TumbleAPIService())
        ServiceLocator.shared.register(analytics: AnalyticsService(appSettings: appSettings))
        ServiceLocator.shared.register(eventStorageService: EventStorageService(appSettings: appSettings))
        ServiceLocator.shared.register(userDataStorageService: UserDataStorageService(appSettings: appSettings))
    }
}

