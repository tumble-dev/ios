//
//  BookmarksSettingsScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

typealias BookmarksSettingsScreenViewModelType = StateStoreViewModel<BookmarksSettingsScreenViewState, BookmarksSettingsScreenViewAction>

class BookmarksSettingsScreenViewModel: BookmarksSettingsScreenViewModelType, BookmarksSettingsScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let eventStorageService: EventStorageServiceProtocol
    
    private var actionsSubject: PassthroughSubject<BookmarksSettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<BookmarksSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appSettings: AppSettings, eventStorageService: EventStorageServiceProtocol) {
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        
        // Create bindings with simple toggle callback (no data deletion)
        let bindings = BookmarksSettingsScreenViewStateBindings(
            appSettings: appSettings,
            eventStorageService: eventStorageService,
            onToggleAction: { [weak appSettings] programmeId, isEnabled in
                guard let appSettings = appSettings else { return }
                
                // Simply update the visibility flag - don't touch the stored events
                var updatedProgrammes = appSettings.bookmarkedProgrammes
                updatedProgrammes[programmeId] = isEnabled
                appSettings.bookmarkedProgrammes = updatedProgrammes
            }
        )
        
        super.init(initialViewState: .init(
            bookmarkedProgrammes: appSettings.bookmarkedProgrammes,
            bindings: bindings
        ))
        
        setupObservers()
    }
    
    override func process(viewAction: BookmarksSettingsScreenViewAction) {
        switch viewAction {
        case .removeAllBookmarks:
            handleRemoveAllBookmarks()
        case .toggleProgramme(let id, let isEnabled):
            handleToggleProgramme(id: id, isEnabled: isEnabled)
        }
    }
    
    func setupObservers() {
        appSettings.$bookmarkedProgrammes
            .sink { [weak self] bookmarkedProgrammes in
                guard let self else { return }
                state.bookmarkedProgrammes = bookmarkedProgrammes
            }
            .store(in: &cancellables)
    }
    
    private func handleToggleProgramme(id: String, isEnabled: Bool) {
        var updatedProgrammes = appSettings.bookmarkedProgrammes
        updatedProgrammes[id] = isEnabled
        appSettings.bookmarkedProgrammes = updatedProgrammes
    }
    
    private func handleRemoveAllBookmarks() {
        for (programmeId, _) in state.bookmarkedProgrammes {
            do {
                try eventStorageService.removeEvents(forProgrammeId: programmeId)
                actionsSubject.send(.popBack)
            } catch let error {
                AppLogger.shared.error("Failed to remove bookmarks related events from local storage for \(programmeId): \(error.localizedDescription)")
            }
        }
        // Clear all bookmarked programmes
        appSettings.bookmarkedProgrammes = [:]
    }
}
