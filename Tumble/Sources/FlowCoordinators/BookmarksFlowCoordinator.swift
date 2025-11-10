//
//  BookmarksFlowCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import SwiftUI
import UIKit

enum BookmarksFlowCoordinatorAction {
    case clearCache
}

class BookmarksFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    private let stateMachine: BookmarksFlowCoordinatorStateMachine
    
    private let onboardingFlowCoordinator: OnboardingFlowCoordinator
    private let settingsFlowCoordinator: SettingsFlowCoordinator
    private let searchFlowCoordinator: SearchFlowCoordinator
    private let accountFlowCoordinator: AccountFlowCoordinator
    
    private let selectedBookmarkEventSubjectId = CurrentValueSubject<String?, Never>(nil)
    
    private var searchScreenCoordinator: SearchScreenCoordinator?
    private var eventDetailsScreenCoordinator: EventDetailsScreenCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let tumbleApiService: TumbleApiServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let userDataStorageService: UserDataStorageServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let eventStorageService: EventStorageServiceProtocol
    private let notificationManager: NotificationManagerProtocol
    
    private let actionsSubject: PassthroughSubject<BookmarksFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<BookmarksFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        appMediator: AppMediatorProtocol,
        notificationManager: NotificationManagerProtocol,
        tumbleApiService: TumbleApiServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        authenticationService: AuthenticationServiceProtocol,
        userDataStorageService: UserDataStorageServiceProtocol,
        eventStorageService: EventStorageServiceProtocol,
        navigationRootCoordinator: NavigationRootCoordinator,
        isFirstOpen: Bool
    ) {
        stateMachine = BookmarksFlowCoordinatorStateMachine()
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        self.appMediator = appMediator
        self.tumbleApiService = tumbleApiService
        self.authenticationService = authenticationService
        self.analyticsService = analyticsService
        self.userDataStorageService = userDataStorageService
        self.notificationManager = notificationManager
        navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator) // Add this
        
        onboardingFlowCoordinator = OnboardingFlowCoordinator(
            appSettings: appSettings,
            analyticsService: analyticsService,
            notificationManager: notificationManager,
            isFirstOpen: isFirstOpen,
            navigationRootCoordinator: navigationRootCoordinator
        )
        
        settingsFlowCoordinator = SettingsFlowCoordinator(
            parameters: .init(
                windowManager: appMediator.windowManager,
                appSettings: appSettings,
                eventStorageService: eventStorageService,
                analyticsService: analyticsService,
                authenticationService: authenticationService,
                navigationSplitCoordinator: navigationSplitCoordinator
            )
        )
        
        searchFlowCoordinator = SearchFlowCoordinator(
            parameters: .init(
                windowManager: appMediator.windowManager,
                appSettings: appSettings,
                tumbleApiService: tumbleApiService,
                eventStorageService: eventStorageService,
                analyticsService: analyticsService,
                navigationSplitCoordinator: navigationSplitCoordinator
            )
        )
        
        accountFlowCoordinator = AccountFlowCoordinator(
            parameters: .init(
                windowManager: appMediator.windowManager,
                appSettings: appSettings,
                tumbleApiService: tumbleApiService,
                eventStorageService: eventStorageService,
                userDataStorageService: userDataStorageService,
                authenticationService: authenticationService,
                analyticsService: analyticsService,
                navigationSplitCoordinator: navigationSplitCoordinator
            )
        )
        
        setupStateMachine()
        setupServices()
        setupObservers()
    }
    
    private func setupServices() {
        Task { await authenticationService.initialize() }
    }
    
    private func setupObservers() {
        settingsFlowCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentedSettings:
                    stateMachine.processEvent(.showSettingsScreen)
                case .dismissedSettings:
                    stateMachine.processEvent(.dismissedSettingsScreen)
                }
            }
            .store(in: &cancellables)
        
        searchFlowCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentedSearch:
                    stateMachine.processEvent(.showSearchScreen)
                case .dismissedSearch:
                    stateMachine.processEvent(.dismissedSearchScreen)
                }
            }
            .store(in: &cancellables)
        
        accountFlowCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentedAccount:
                    break
                case .dismissedAccount:
                    stateMachine.processEvent(.dismissedAccountScreen)
                }
            }
            .store(in: &cancellables)
    }
    
    func attemptStartingOnboarding() {
        AppLogger.shared.info("Attempting to start onboarding")
        
        if onboardingFlowCoordinator.shouldStart {
            AppLogger.shared.info("[BookmarksFlowCoordinator] Onboarding should not happen")
            clearRoute(animated: false)
            onboardingFlowCoordinator.start()
        }
    }
    
    // MARK: - FlowCoordinatorProtocol
    
    func start() {
        stateMachine.processEvent(.start)
    }
    
    func stop() {}
    
    func clearRoute(animated: Bool) {
        
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func clearPresentedSheets(animated: Bool) async {
        if navigationSplitCoordinator.sheetCoordinator == nil {
            return
        }
        
        navigationSplitCoordinator.setSheetCoordinator(nil, animated: animated)
        
        // Prevents system crashes when presenting a sheet if another one was already shown
        try? await Task.sleep(nanoseconds: 200_000)
    }
    
}

// MARK: - Setup

private extension BookmarksFlowCoordinator {
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            switch (context.fromState, context.event, context.toState) {
            /// Initial -> Bookmarks
            case (.initial, .start, .bookmarks):
                presentBookmarksScreen()
                attemptStartingOnboarding()
            /// Account -> Bookmarks
            case (.accountScreen, .dismissedAccountScreen, .bookmarks):
                break
            case (.bookmarks, .showAccountScreen, .accountScreen):
                break
            /// Settings -> Bookmarks
            case (.settingsScreen, .dismissedSettingsScreen, .bookmarks):
                break
            case (.bookmarks, .showSettingsScreen, .settingsScreen):
                break
            case (.searchScreen, .dismissedSearchScreen, .bookmarks):
                break
            case (.bookmarks, .showSearchScreen, .searchScreen):
                break
            case (.eventDetailsScreen, .dismissedEventDetails, .bookmarks):
                break
            case (.bookmarks, .showEventDetails(let eventId), .eventDetailsScreen):
                presentEventDetailsSreen(eventId: eventId)
            case (.eventDetailsScreen, .showEventDetails(let eventId), .eventDetailsScreen):
                presentEventDetailsSreen(eventId: eventId)
            case (.eventDetailsScreen, .showAccountScreen, .accountScreen):
                accountFlowCoordinator.handleAppRoute(.account, animated: true)
            case (.bookmarks, .dismissedEventDetails, .bookmarks):
                break
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addTransitionHandler { [weak self] context in
            switch context.toState {
            case .eventDetailsScreen(let eventId):
                self?.selectedBookmarkEventSubjectId.send(eventId)
            default:
                break
            }
        }
        
        stateMachine.addErrorHandler { context in
            if context.fromState == context.toState {
                AppLogger.shared.error("Failed transition from equal states: \(context.fromState)")
            } else {
                fatalError("Failed transition with context: \(context)")
            }
        }
    }
}

// MARK: - Showing Screens

private extension BookmarksFlowCoordinator {
    /// Single home screen instead of tabs
    private func presentBookmarksScreen() {
        let parameters = BookmarksScreenCoordinatorParameters(
            appSettings: appSettings,
            eventStorageService: eventStorageService
        )
        let coordinator = BookmarksScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentBookmarkedEventDetails(let eventId):
                    stateMachine.processEvent(.showEventDetails(eventId: eventId))
                case .presentSettingsScreen:
                    settingsFlowCoordinator.handleAppRoute(.settings, animated: true)
                case .presentSearchScreen:
                    searchFlowCoordinator.handleAppRoute(.search, animated: true)
                case .presentAccountScreen:
                    accountFlowCoordinator.handleAppRoute(.account, animated: true)
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
            
        // Only set detail on iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            detailNavigationStackCoordinator.setRootCoordinator(PlaceholderScreenCoordinator())
        }
        
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)
    }

    private func presentEventDetailsSreen(eventId: String) {
        let parameters = EventDetailsScreenCoordinatorParameters(
            eventId: eventId,
            appSettings: appSettings,
            eventStorageService: eventStorageService,
            notificationManager: notificationManager
        )
        
        let coordinator = EventDetailsScreenCoordinator(parameters: parameters)
        eventDetailsScreenCoordinator = coordinator
        
        coordinator.actions
            .sink { [weak self] actions in
                guard let self else { return }
                switch actions {
                case .dismiss:
                    // Reset to placeholder
                    detailNavigationStackCoordinator.setRootCoordinator(PlaceholderScreenCoordinator())
                    stateMachine.processEvent(.dismissedEventDetails)
                }
            }
            .store(in: &cancellables)
        
        // Show in detail pane on iPad, pushes on iPhone (split view auto-collapses)
        detailNavigationStackCoordinator.setRootCoordinator(coordinator)
    }
}
