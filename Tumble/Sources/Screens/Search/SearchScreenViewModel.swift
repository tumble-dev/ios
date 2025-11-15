//
//  SearchScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import Foundation

typealias SearchScreenViewModelType = StateStoreViewModel<SearchScreenViewState, SearchScreenViewAction>

class SearchScreenViewModel: SearchScreenViewModelType {
    let tumbleApiService: TumbleApiServiceProtocol
    
    private var actionsSubject: PassthroughSubject<SearchScreenViewModelAction, Never> = .init()
    
    // Task for search operation that can be cancelled
    private var searchTask: Task<Void, Never>?
    
    var actions: AnyPublisher<SearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(tumbleApiService: TumbleApiServiceProtocol) {
        self.tumbleApiService = tumbleApiService
        super.init(initialViewState: .init())
    }
    
    deinit {
        // Cancel any ongoing search tasks when the view model is deallocated
        searchTask?.cancel()
        AppLogger.shared.info("[SearchScreenViewModel] Deallocated and cancelled ongoing tasks")
    }
    
    override func process(viewAction: SearchScreenViewAction) {
        switch viewAction {
        case .openProgrammeEvents(let programmeId, let school):
            actionsSubject.send(.openProgrammeEvents(programmeId: programmeId, school: school))
        case .search(let query):
            // Cancel any existing search task before starting a new one
            searchTask?.cancel()
            searchTask = Task {
                await search(for: query)
            }
        case .selectSchool(let school):
            // Cancel ongoing search when selecting new school
            searchTask?.cancel()
            state.selectedSchool = school
            state.dataState = .initial
        case .changeSchool:
            // Cancel ongoing search when changing school
            searchTask?.cancel()
            state.selectedSchool = nil
            state.dataState = .initial
        case .clearSearch:
            // Cancel ongoing search when clearing
            searchTask?.cancel()
            state.dataState = .initial
        case .close:
            // Cancel ongoing search when closing
            searchTask?.cancel()
            actionsSubject.send(.dismiss)
        }
    }
    
    private func search(for query: String) async {
        // Check if the task was cancelled before starting
        guard !Task.isCancelled else {
            AppLogger.shared.info("[SearchScreenViewModel] Search task was cancelled")
            return
        }
        
        do {
            await MainActor.run {
                state.dataState = .loading
            }
            
            guard !Task.isCancelled else {
                AppLogger.shared.info("[SearchScreenViewModel] Search task cancelled before checking school")
                return
            }
            
            guard let selectedSchool = state.selectedSchool else {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    state.dataState = .error("No school passed in query")
                }
                return
            }
            
            let res: Response.ProgrammeSearchResponse = try await tumbleApiService.searchProgrammes(query: query, school: selectedSchool.id)
            
            // Check cancellation before updating UI
            guard !Task.isCancelled else {
                AppLogger.shared.info("[SearchScreenViewModel] Search task cancelled after API call")
                return
            }
            
            await MainActor.run {
                state.dataState = .loaded(res.programmes)
            }
            
            AppLogger.shared.info("[SearchScreenViewModel] Successfully searched for programmes using query '\(query)'")
            
        } catch is CancellationError {
            AppLogger.shared.info("[SearchScreenViewModel] Search task was cancelled")
        } catch (let error) {
            guard !Task.isCancelled else {
                AppLogger.shared.info("[SearchScreenViewModel] Search task cancelled during error handling")
                return
            }
            
            AppLogger.shared.info("[SearchScreenViewModel] Error searching for programmes using query '\(query)': \(error)")
            await MainActor.run {
                state.dataState = .error(error.localizedDescription)
            }
        }
    }
}
