//
//  SearchScreenViewModel.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import Combine

typealias SearchScreenViewModelType = StateStoreViewModel<SearchScreenViewState, SearchScreenViewAction>

class SearchScreenViewModel: SearchScreenViewModelType {
    let tumbleApiService: TumbleAPIService
    
    private var actionsSubject: PassthroughSubject<SearchScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(tumbleApiService: TumbleAPIService) {
        self.tumbleApiService = tumbleApiService
        super.init(initialViewState: .init())
    }
    
    override func process(viewAction: SearchScreenViewAction) {
        switch viewAction {
        case .openProgrammeEvents(let programmeId, let school):
            actionsSubject.send(.openProgrammeEvents(programmeId: programmeId, school: school))
        case .search(let query):
            Task {
                await search(for: query)
            }
        case .selectSchool(let school):
            state.selectedSchool = school
            state.dataState = .initial
        case .changeSchool:
            state.selectedSchool = nil
            state.dataState = .initial
        case .clearSearch:
            state.dataState = .initial
        }
    }
    
    private func search(for query: String) async {
        do {
            state.dataState = .loading
            guard let selectedSchool = state.selectedSchool else {
                await MainActor.run {
                    state.dataState = .error("No school passed in query")
                }
                return
            }
            let res: Response.ProgrammeSearchResponse = try await tumbleApiService.searchProgrammes(query: query, school: selectedSchool.id)
            await MainActor.run {
                state.dataState = .loaded(res.programmes)
            }
        } catch (let error) {
            AppLogger.shared.info("[SearchScreenViewModel] Error searching for programmes using query '\(query)'")
            await MainActor.run {
                state.dataState = .error(error.localizedDescription)
            }
        }
    }
}
