//
//  BookmarksCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import SwiftUI

struct BookmarksScreenCoordinatorParameters {
    let appSettings: AppSettings
    let eventStorageService: EventStorageService
}

enum BookmarksScreenCoordinatorAction {
    case presentBookmarkedEventDetails(eventId: String)
    case presentSettingsScreen
    case presentSearchScreen
}

final class BookmarksScreenCoordinator: CoordinatorProtocol {
    private var viewModel: BookmarksViewModel
    private let actionsSubject: PassthroughSubject<BookmarksScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<BookmarksScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: BookmarksScreenCoordinatorParameters) {
        viewModel = BookmarksViewModel(
            appSettings: parameters.appSettings,
            eventStorageService: parameters.eventStorageService
        )
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            AppLogger.shared.debug("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .presentEventDetails(let eventId):
                actionsSubject.send(.presentBookmarkedEventDetails(eventId: eventId))
            case .presentSearchScreen:
                actionsSubject.send(.presentSearchScreen)
            case .presentSettingsScreen:
                actionsSubject.send(.presentSettingsScreen)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(BookmarksScreen(context: viewModel.context))
    }
}
