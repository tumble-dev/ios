//
//  ApplicationCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import SwiftUI
import UIKit
import UserNotifications

class ApplicationCoordinator: ApplicationCoordinatorProtocol, NotificationManagerDelegate {
    let windowManager: WindowManagerProtocol

    private let appSettings: AppSettings

    private let notificationManager: NotificationManagerProtocol
    private let keychainController: KeychainControllerProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let websocketSessionManager: WebSocketSessionManagerProtocol

    private let appDelegate: AppDelegate
    private let appMediator: AppMediator
    private let appHooks: AppHooks

    private var userSessionObserver: AnyCancellable?
    private var appDelegateObserver: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    private var bookmarksFlowCoordinator: BookmarksFlowCoordinator?
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let stateMachine: ApplicationCoordinatorStateMachine

    private var storedAppRoute: AppRoute?

    init(appDelegate: AppDelegate) {
        let appHooks = AppHooks()
        appHooks.setUp()

        let appSettings = appHooks.appSettingsHook.configure(AppSettings())

        windowManager = WindowManager(appDelegate: appDelegate)
        let networkMonitor = NetworkMonitor()
        appMediator = AppMediator(windowManager: windowManager, networkMonitor: networkMonitor)
        Self.setupServiceLocator(appSettings: appSettings, appHooks: appHooks)

        // MARK: - Services, Managers & Controllers

        notificationManager = NotificationManager(
            notificationCenter: UNUserNotificationCenter.current(),
            appSettings: appSettings,
            eventStorageService: ServiceLocator.shared.eventStorageService
        )

        keychainController = KeychainController(accessGroup: Config.keychainAccessGroupIdentifier)

        websocketSessionManager = WebSocketSessionManager(webSocketURL: Config.webSocketURL)

        authenticationService = AuthenticationService(
            keychainController: keychainController,
            userDataStorage: ServiceLocator.shared.userDataStorageService,
            tumbleApiService: ServiceLocator.shared.tumbleApiService,
            appSettings: appSettings,
            webSocketSessionManager: websocketSessionManager
        )

        // MARK: - Navigation & State

        stateMachine = ApplicationCoordinatorStateMachine()
        navigationRootCoordinator = NavigationRootCoordinator()

        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        self.appDelegate = appDelegate
        self.appSettings = appSettings
        self.appHooks = appHooks

        // Wire delegate and subscribe to AppDelegate callbacks BEFORE starting notifications,
        // otherwise the APNs token event can be missed (PassthroughSubject has no buffer).
        notificationManager.delegate = self
        configureNotificationManager()
        notificationManager.start()

        setupStateMachine()
    }

    func start() {
        guard stateMachine.state == .initial else {
            AppLogger.shared.error("Received a start request when already started")
            return
        }

        stateMachine.processEvent(.start)
    }

    func stop() {}

    func toPresentable() -> AnyView {
        return AnyView(
            navigationRootCoordinator
                .toPresentable()
                .onReceive(appSettings.$appearance) { [weak self] appearance in
                    guard let self else { return }

                    for window in windowManager.windows {
                        window.overrideUserInterfaceStyle = appearance.interfaceStyle
                    }
                }
        )
    }

    /// Initializes and starts the main coordinator flow
    func startMainFlow(isFirstOpen: Bool = false) {
        let bookmarksFlowCoordinator = BookmarksFlowCoordinator(
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

        bookmarksFlowCoordinator.actionsPublisher
            .sink { [weak self] (action: BookmarksFlowCoordinatorAction) in
                guard let self else { return }

                switch action {
                case .clearCache:
                    stateMachine.processEvent(.clearCache)
                }
            }
            .store(in: &cancellables)
        bookmarksFlowCoordinator.start()
        self.bookmarksFlowCoordinator = bookmarksFlowCoordinator
    }

    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        // TODO: Implement
        return false
    }

    private func handleAppRoute(_ appRoute: AppRoute) {
        var handled = false
        switch appRoute {
        case .eventDetails(let eventId):
            if let bookmarksFlowCoordinator {
                bookmarksFlowCoordinator.handleAppRoute(.eventDetails(eventId: eventId), animated: true)
                handled = true
            }
        default:
            break
        }

        if !handled {
            storedAppRoute = appRoute
        }
    }
}

// MARK: - NotificationManagerDelegate

extension ApplicationCoordinator {
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool {
        // TODO: Check if BookmarksFlowCoordinator is currently displaying the
        // event details screen with this passed ID
        return true
    }

    func notificationTapped(content: UNNotificationContent) async {
        if let eventId = content.userInfo[NotificationConstants.EventInfoKey.eventId] as? String {
            if ServiceLocator.shared.eventStorageService.eventExists(id: eventId) {
                handleAppRoute(.eventDetails(eventId: eventId))
            }
        }
        // TODO: Check for bookmark notification as well
    }
    
    func openEventDetails(eventId: String) async {
        AppLogger.shared.info("[ApplicationCoordinator] Opening event details for event ID: \(eventId)")
        
        // Ensure we're on the main actor since we're dealing with UI navigation
        await MainActor.run {
            handleAppRoute(.eventDetails(eventId: eventId))
        }
    }

    func registerForRemoteNotifications() {
        AppLogger.shared.info("[ApplicationCoordinator] registerForRemoteNotifications called - calling UIApplication.shared.registerForRemoteNotifications()")
        UIApplication.shared.registerForRemoteNotifications()
    }

    func unregisterForRemoteNotifications() {
        AppLogger.shared.info("[ApplicationCoordinator] unregisterForRemoteNotifications called")
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
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.startMainFlow(isFirstOpen: true)
                }

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
                    AppLogger.shared.info("[ApplicationCoordinator] AppDelegate callback: Registering with device token \(deviceToken)")
                    Task { await self?.notificationManager.register(with: deviceToken) }
                case .failedToRegisteredNotifications(let error):
                    AppLogger.shared.error("[ApplicationCoordinator] AppDelegate callback: Failed to register for notifications with error: \(error)")
                    self?.notificationManager.registrationFailed(with: error)
                case .receivedFCMToken(let token):
                    AppLogger.shared.info("[ApplicationCoordinator] AppDelegate callback: Received FCM token: \(token)")
                    Task { await self?.notificationManager.registerWithFCMToken(token) }
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
