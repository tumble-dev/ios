//
//  SearchFlowCoordinator.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

enum SearchFlowCoordinatorAction {
    case presentedSearch
    case dismissedSearch
}

struct SearchFlowCoordinatorParameters {
    let windowManager: WindowManagerProtocol
    let appSettings: AppSettings
    let tumbleApiService: TumbleApiServiceProtocol
    let eventStorageService: EventStorageServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    let navigationSplitCoordinator: NavigationSplitCoordinator
}

class SearchFlowCoordinator: FlowCoordinatorProtocol {
    private let parameters: SearchFlowCoordinatorParameters
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SearchFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SearchFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SearchFlowCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func start() {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .search:
            presentSearchScreen(animated: animated)
        default:
            break
        }
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
    
    // MARK: - Private
    
    private func presentSearchScreen(animated: Bool) {
        navigationStackCoordinator = NavigationStackCoordinator()
        
        let searchScreenCoordinator = SearchScreenCoordinator(
            parameters: .init(
                tumbleApiService: parameters.tumbleApiService
            )
        )
        
        searchScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                    
                case .quickView(programmeId: let programmeId, school: let school):
                    presentSearchQuickView(programmeId: programmeId, school: school)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(searchScreenCoordinator, animated: animated)
        
        parameters.navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            // notify BookmarksFlowCoordinator to properly set state
            actionsSubject.send(.dismissedSearch)
        }
        
        // notify BookmarksFlowCoordinator to properly set state
        actionsSubject.send(.presentedSearch)
    }
    
    // MARK: - Navigation Methods
    
    private func presentSearchQuickView(programmeId: String, school: String) {
        let coordinator = QuickViewScreenCoordinator(
            parameters: .init(
                appSettings: parameters.appSettings,
                tumbleApiService: parameters.tumbleApiService,
                eventStorageService: parameters.eventStorageService,
                programmeId: programmeId,
                school: school
            )
        )
        navigationStackCoordinator.push(coordinator)
    }
}
