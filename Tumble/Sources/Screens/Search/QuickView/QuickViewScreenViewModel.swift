//
//  QuickViewScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import Foundation

typealias QuickViewScreenViewModelType = StateStoreViewModel<QuickViewScreenViewState, QuickViewScreenViewAction>

class QuickViewScreenViewModel: QuickViewScreenViewModelType {
    let appSettings: AppSettings
    let tumbleApiService: TumbleApiServiceProtocol
    let eventStorageService: EventStorageServiceProtocol
    let programmeId: String
    let school: String
    
    private var actionsSubject: PassthroughSubject<QuickViewScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<QuickViewScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        tumbleApiService: TumbleApiServiceProtocol,
        eventStorageService: EventStorageServiceProtocol,
        programmeId: String,
        school: String
    ) {
        self.appSettings = appSettings
        self.tumbleApiService = tumbleApiService
        self.eventStorageService = eventStorageService
        self.programmeId = programmeId
        self.school = school
        super.init(initialViewState: .init())
        
        Task {
            await fetchEvents(with: programmeId, for: school)
        }
        
        setupListeners()
    }
    
    override func process(viewAction: QuickViewScreenViewAction) {
        switch viewAction {
        case .toggleBookmark(let events):
            toggleBookmark(events: events)
        }
    }
    
    private func setupListeners() {
        // Listen to appSettings changes to update button state
        appSettings.$bookmarkedProgrammes
            .sink { [weak self] savedData in
                guard let self else { return }
                let isBookmarked = savedData[self.programmeId]?.isVisible ?? false
                self.updateSaveButtonState(isBookmarked ? .saved : .notSaved)
            }
            .store(in: &cancellables)
    }

    private func toggleBookmark(events: [Response.Event]) {
        updateSaveButtonState(.loading)
        
        let isCurrentlyBookmarked = appSettings.isBookmarked(programmeId)
        
        if isCurrentlyBookmarked {
            // Remove from saved programmes and event storage
            appSettings.removeBookmarkedProgramme(programmeId)
            do {
                try eventStorageService.removeEvents(forProgrammeId: programmeId)
            } catch {
                // Revert if removal fails
                appSettings.addBookmarkedProgramme(programmeId, schoolId: school, isVisible: true)
                updateSaveButtonState(.saved)
                return
            }
        } else {
            // Add to saved programmes and save events
            appSettings.addBookmarkedProgramme(programmeId, schoolId: school, isVisible: true)
            do {
                try eventStorageService.saveEvents(events)
            } catch {
                // Revert if saving events fails
                appSettings.removeBookmarkedProgramme(programmeId)
                updateSaveButtonState(.notSaved)
                return
            }
        }
        
        updateSaveButtonState(isCurrentlyBookmarked ? .notSaved : .saved)
        
        // Emit action to indicate bookmark was toggled successfully
        actionsSubject.send(.bookmarkToggled)
    }

    @MainActor
    private func updateSaveButtonState(_ newState: SaveButtonState) {
        state.saveButtonState = newState
    }
    
    private func fetchEvents(with programmeId: String, for school: String) async {
        do {
            updateDataState(newDataState: .loading)
            let res: Response.EventsResponse = try await tumbleApiService.getScheduleEvents(school: school, scheduleIds: [programmeId])
            if res.events.isEmpty {
                updateDataState(newDataState: .empty)
                updateSaveButtonState(.disabled)
                return
            }
            updateDataState(newDataState: .loaded(res.events))
        } catch (let error) {
            updateSaveButtonState(.disabled)
            updateDataState(newDataState: .error(error.localizedDescription))
        }
    }
    
    @MainActor
    private func updateDataState(newDataState: QuickViewScreenViewDataState) {
        state.dataState = newDataState
    }
}
