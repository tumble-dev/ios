//
//  SearchView-ViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/17/22.
//

import Combine
import Foundation
import SwiftUI

/// ViewModel handling interaction with KronoxManager
/// for finding schedules for specific schools
/// and displaying search results.
final class SearchViewModel: ObservableObject {
    let viewModelFactory: ViewModelFactory = .shared
    
    @Inject var preferenceManager: PreferenceManager
    @Inject var kronoxManager: KronoxManager
    @Inject var notificationManager: NotificationManager
    @Inject var schoolManager: SchoolManager
    
    @Published var status: SearchStatus = .initial
    @Published var programmeSearchResults: [Response.Programme] = []
    @Published var errorMessageSearch: String? = nil
    @Published var searchPreviewModel: SearchPreviewModel? = nil
    @Published var schoolNotSelected: Bool = true
    @Published var selectedSchool: School? = nil
    @Published var universityImage: Image? = nil
    @Published var searching: Bool = false
    @Published var searchBarText: String = ""
    
    var currentSearchTask: Task<Void, Never>? = nil
    
    lazy var schools: [School] = schoolManager.getSchools()
    lazy var searchPreviewViewModel: SearchPreviewViewModel = viewModelFactory.makeViewModelSearchPreview()
    
    /// Searches for the input given by the user and attempts
    /// to find matching university programmes and schedules
    func search(for query: String, selectedSchoolId: Int) {
        self.status = .loading
        
        // Cancel the ongoing task if there is one
       currentSearchTask?.cancel()
        
        currentSearchTask = Task {
                do {
                    let endpoint = Endpoint.searchProgramme(searchQuery: query, schoolId: String(selectedSchoolId))
                    let searchResult: Response.Search = try await self.kronoxManager.get(endpoint)
                    
                    // Before parsing the results, check if the task should proceed
                    if self.status != .loading {
                        return
                    }
                    
                    await self.parseSearchResults(searchResult)
                } catch {
                    DispatchQueue.main.async {
                        if (error as? CancellationError) != nil {
                            return
                        }
                    }
                }
            }
    }

    /// Resets any fields and data in the `Search` and
    /// `SearchResults` views
    @MainActor func resetSearchResults() {
        programmeSearchResults = []
        currentSearchTask?.cancel()
        status = .initial
    }
    
    /// Maps data given in `Response.Search` to
    /// `[Response.Programme]` and updates view state
    @MainActor func parseSearchResults(_ results: Response.Search) {
        programmeSearchResults = results.items.map { $0 }
        status = .loaded
    }
}
