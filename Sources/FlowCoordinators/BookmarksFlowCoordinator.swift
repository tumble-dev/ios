//
//  BookmarksFlowCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import UIKit
import Combine
import SwiftUI

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
    
    private let selectedBookmarkEventSubjectId = CurrentValueSubject<String?, Never>(nil)
    
    private var searchScreenCoordinator: SearchScreenCoordinator?
    private var eventDetailsScreenCoordinator: EventDetailsScreenCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let tumbleApiService: TumbleAPIService
    private let analyticsService: AnalyticsServiceProtocol
    private let eventStorageService: EventStorageService
    private let notificationManager: NotificationManagerProtocol
    
    private let actionsSubject: PassthroughSubject<BookmarksFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<BookmarksFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        appMediator: AppMediatorProtocol,
        notificationManager: NotificationManagerProtocol,
        tumbleApiService: TumbleAPIService,
        analyticsService: AnalyticsServiceProtocol,
        eventStorageService: EventStorageService,
        navigationRootCoordinator: NavigationRootCoordinator,
        isFirstOpen: Bool
    ) {
        self.stateMachine = BookmarksFlowCoordinatorStateMachine()
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        self.appMediator = appMediator
        self.tumbleApiService = tumbleApiService
        self.analyticsService = analyticsService
        self.notificationManager = notificationManager
        self.navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        
        self.sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        self.detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        self.navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        self.onboardingFlowCoordinator = OnboardingFlowCoordinator(
            appSettings: appSettings,
            analyticsService: analyticsService,
            notificationManager: notificationManager,
            isFirstOpen: isFirstOpen,
            rootNavigationStackCoordinator: detailNavigationStackCoordinator
        )
        
        self.settingsFlowCoordinator = SettingsFlowCoordinator(
            parameters: .init(
                windowManager: appMediator.windowManager,
                appSettings: appSettings,
                eventStorageService: eventStorageService,
                analyticsService: analyticsService,
                navigationSplitCoordinator: navigationSplitCoordinator
            )
        )
        
        self.searchFlowCoordinator = SearchFlowCoordinator(
            parameters: .init(
                windowManager: appMediator.windowManager,
                appSettings: appSettings,
                tumbleApiService: tumbleApiService,
                eventStorageService: eventStorageService,
                analyticsService: analyticsService,
                navigationSplitCoordinator: navigationSplitCoordinator
            )
        )
        
        setupStateMachine()
        setupObservers()
    }
    
    func setupObservers() {
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
    
    func stop() { }
    
    func clearRoute(animated: Bool) {
        // TODO: bookmarkEventFlowCoordinator?.clearRoute(animated: animated)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        Task {
            await asyncHandleAppRoute(appRoute, animated: animated)
        }
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
    
    func asyncHandleAppRoute(_ appRoute: AppRoute, animated: Bool) async {
        switch appRoute {
        default:
            break
        }
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
            /// Bookmarks -> Account
            case (.bookmarks, .showSettingsScreen, .settingsScreen):
                break
            /// Settings -> Bookmarks
            case (.settingsScreen, .dismissedSettingsScreen, .bookmarks):
                break
            /// Account -> Bookmarks
            case (.accountScreen, .dismissedAccountScreen, .bookmarks):
                break
            
            case (.searchScreen, .dismissedSearchScreen, .bookmarks):
                break
            case (.bookmarks, .showSearchScreen, .searchScreen):
                break
            case (.eventDetailsScreen, .dismissedEventDetails, .bookmarks):
                break
                
            case (.bookmarks, .showEventDetails(let eventId), .eventDetailsScreen):
                presentEventDetailsSreen(eventId: eventId)
                
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
                    break
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)
    }
    
    private func presentEventDetailsSreen(eventId: String) {
        
        let eventDetailsStackCoordinator = NavigationStackCoordinator()
        
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
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        eventDetailsStackCoordinator.setRootCoordinator(coordinator)
        navigationSplitCoordinator.setSheetCoordinator(eventDetailsStackCoordinator, animated: true) { [weak self] in
            self?.stateMachine.processEvent(.dismissedEventDetails)
        }
    }
}
