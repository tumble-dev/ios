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
    case openSearch
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
        
    }
            
    func toPresentable() -> AnyView {
        AnyView(BookmarksSettingsScreen(context: viewModel.context))
    }
}
