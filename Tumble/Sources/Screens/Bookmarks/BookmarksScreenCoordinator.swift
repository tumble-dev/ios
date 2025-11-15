//
//  BookmarksScreenCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import SwiftUI

struct BookmarksScreenCoordinatorParameters {
    let appSettings: AppSettings
    let eventStorageService: EventStorageServiceProtocol
}

enum BookmarksScreenCoordinatorAction {
    case presentBookmarkedEventDetails(eventId: String)
    case presentSettingsScreen
    case presentSearchScreen
    case presentAccountScreen
}

final class BookmarksScreenCoordinator: CoordinatorProtocol {
    private var viewModel: BookmarksScreenViewModel
    private let actionsSubject: PassthroughSubject<BookmarksScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<BookmarksScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: BookmarksScreenCoordinatorParameters) {
        viewModel = BookmarksScreenViewModel(
            appSettings: parameters.appSettings,
            eventStorageService: parameters.eventStorageService
        )
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            AppLogger.shared.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .presentEventDetails(let eventId):
                actionsSubject.send(.presentBookmarkedEventDetails(eventId: eventId))
            case .presentSearchScreen:
                actionsSubject.send(.presentSearchScreen)
            case .presentSettingsScreen:
                actionsSubject.send(.presentSettingsScreen)
            case .presentAccountScreen:
                actionsSubject.send(.presentAccountScreen)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(BookmarksScreen(context: viewModel.context))
    }
}
