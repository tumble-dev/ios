//
//  MainFlowCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import UIKit
import Combine
import SwiftUI

enum MainFlowCoordinatorAction {
    case clearCache
}

class MainFlowCoordinator: FlowCoordinatorProtocol {
    
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    private let stateMachine: MainFlowCoordinatorStateMachine
    
    private let onboardingFlowCoordinator: OnboardingFlowCoordinator
    
    private let selectedBookmarkEventSubjectId = CurrentValueSubject<String?, Never>(nil)
    
    private var searchScreenCoordinator: SearchScreenCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let tumbleApiService: TumbleAPIService
    private let eventStorageService: EventStorageService
    private let notificationManager: NotificationManagerProtocol
    
    private let actionsSubject: PassthroughSubject<MainFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MainFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        appMediator: AppMediatorProtocol,
        notificationManager: NotificationManagerProtocol,
        tumbleApiService: TumbleAPIService,
        eventStorageService: EventStorageService,
        navigationRootCoordinator: NavigationRootCoordinator,
        isFirstOpen: Bool
    ) {
        self.stateMachine = MainFlowCoordinatorStateMachine()
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        self.appMediator = appMediator
        self.tumbleApiService = tumbleApiService
        self.notificationManager = notificationManager
        self.navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        
        self.sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        self.detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        self.navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        self.onboardingFlowCoordinator = OnboardingFlowCoordinator(
            appSettings: appSettings,
            notificationManager: notificationManager,
            isFirstOpen: isFirstOpen,
            rootNavigationStackCoordinator: detailNavigationStackCoordinator
        )
        
        setupStateMachine()
    }
    
    func setupObservers() {
        // TODO
    }
    
    func attemptStartingOnboarding() {
        AppLogger.shared.info("Attempting to start onboarding")
        
        if onboardingFlowCoordinator.shouldStart {
            AppLogger.shared.info("[MainFlowCoordinator] Onboarding should not happen")
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
        case .bookmarks:
            break
        case .eventDetails(let eventId):
            break
        case .search:
            break
        case .searchResult(let query):
            break
        case .searchQuickview(let programmeId):
            break
        case .account:
            break
        case .settings:
            break
        case .settingsDetails(let category):
            break
        }
    }
}

// MARK: - Setup

private extension MainFlowCoordinator {
    
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
                presentSettingsScreen()
            /// Settings -> Bookmarks
            case (.settingsScreen, .dismissedSettingsScreen, .bookmarks):
                presentBookmarksScreen()
            /// Account -> Bookmarks
            case (.accountScreen, .dismissedAccountScreen, .bookmarks):
                presentBookmarksScreen()
                
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

private extension MainFlowCoordinator {
    
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
                    presentEventDetailsSreen(eventId: eventId)
                case .presentSettingsScreen:
                    presentSettingsScreen()
                case .presentSearchScreen:
                    presentSearchScreen()
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)
    }
    
    private func presentEventDetailsSreen(eventId: String) { }
    
    private func dismissEventDetailsScreen() { }

    private func presentSearchScreen() {
        
        let searchProgrammeStackCoordinator = NavigationStackCoordinator()
        
        let parameters = SearchScreenCoordinatorParameters(
            tumbleApiService: tumbleApiService,
        )
        let coordinator = SearchScreenCoordinator(parameters: parameters)
        searchScreenCoordinator = coordinator
        
        coordinator.actions
            .sink { [weak self] actions in
                guard let self else { return }
                
                switch actions {
                case .dismiss:
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                case .quickView(let programmeId, let school):
                    let quickViewParameters = QuickViewScreenCoordinatorParameters(
                        appSettings: appSettings,
                        tumbleApiService: tumbleApiService,
                        eventStorageService: eventStorageService,
                        programmeId: programmeId,
                        school: school
                    )
                    let quickViewScreenCoordinator = QuickViewScreenCoordinator(parameters: quickViewParameters)
                    
                    searchProgrammeStackCoordinator.push(quickViewScreenCoordinator, animated: true)
                }
            }
            .store(in: &cancellables)
        
        searchProgrammeStackCoordinator.setRootCoordinator(coordinator)
        
        navigationSplitCoordinator.setSheetCoordinator(searchProgrammeStackCoordinator, animated: true) { [weak self] in
            self?.stateMachine.processEvent(.dismissedSearchScreen)
        }
    }
    
    private func presentSettingsScreen() { }
    
    private func dismissSettingsScreen() {}
    
    private func presentLogoutConfirmationScreen() {}
    
    private func dismissLogoutConfirmationScreen() {}
    
    private func presentLoginScreen() {}
    
    private func dismissLoginScreen() {}
}
