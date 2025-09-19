//
//  QuickViewScreenViewModel.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import Combine

typealias QuickViewScreenViewModelType = StateStoreViewModel<QuickViewScreenViewState, QuickViewScreenViewAction>

class QuickViewScreenViewModel: QuickViewScreenViewModelType {
    let appSettings: AppSettings
    let tumbleApiService: TumbleAPIService
    let eventStorageService: EventStorageService
    let programmeId: String
    
    private var actionsSubject: PassthroughSubject<QuickViewScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<QuickViewScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        tumbleApiService: TumbleAPIService,
        eventStorageService: EventStorageService,
        programmeId: String,
        school: String
    ) {
        self.appSettings = appSettings
        self.tumbleApiService = tumbleApiService
        self.eventStorageService = eventStorageService
        self.programmeId = programmeId
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
        appSettings.$savedProgrammeIds
            .sink { [weak self] savedIds in
                guard let self else { return }
                let isBookmarked = savedIds.contains(self.programmeId)
                self.updateSaveButtonState(isBookmarked ? .saved : .notSaved)
            }
            .store(in: &cancellables)
    }

    private func toggleBookmark(events: [Response.Event]) {
        updateSaveButtonState(.loading)
        
        let isCurrentlyBookmarked = appSettings.savedProgrammeIds.contains(programmeId)
        
        if isCurrentlyBookmarked {
            // Remove from saved programmes and event storage
            appSettings.savedProgrammeIds.removeAll { $0 == programmeId }
            do {
                try eventStorageService.removeEvents(forScheduleId: programmeId)
            } catch {
                // Revert if removal fails
                appSettings.savedProgrammeIds.append(programmeId)
                updateSaveButtonState(.saved)
                return
            }
        } else {
            // Add to saved programmes and save events
            appSettings.savedProgrammeIds.append(programmeId)
            do {
                try eventStorageService.saveEvents(events)
            } catch {
                // Revert if saving events fails
                appSettings.savedProgrammeIds.removeAll { $0 == programmeId }
                updateSaveButtonState(.notSaved)
                return
            }
        }
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
            updateDataState(newDataState: .error(error.localizedDescription))
        }
    }
    
    @MainActor
    private func updateDataState(newDataState: QuickViewScreenViewDataState) {
        state.dataState = newDataState
    }
}
