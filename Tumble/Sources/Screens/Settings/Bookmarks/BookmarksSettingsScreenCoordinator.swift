//
//  BookmarksSettingsScreenCoordinator.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

struct BookmarksSettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
    let eventStorageService: EventStorageServiceProtocol
}

enum BookmarksSettingsScreenCoordinatorAction {
    case dismiss
}

final class BookmarksSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: BookmarksSettingsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<BookmarksSettingsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<BookmarksSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: BookmarksSettingsScreenCoordinatorParameters) {
        viewModel = BookmarksSettingsScreenViewModel(
            appSettings: parameters.appSettings,
            eventStorageService: parameters.eventStorageService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .popBack:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
        
    }
            
    func toPresentable() -> AnyView {
        AnyView(BookmarksSettingsScreen(context: viewModel.context))
    }
}
