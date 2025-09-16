//
//  SearchView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/17/22.
//

import SwiftUI

struct Search: View {
    @ObservedObject var viewModel: SearchViewModel
    let appController: AppController = .shared
        
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.medium) {
                switch viewModel.status {
                case .initial:
                    SearchInfo(schools: viewModel.schools, selectedSchool: $viewModel.selectedSchool)
                        .padding(.bottom, Spacing.medium)
                case .loading:
                    CustomProgressIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                case .loaded:
                    SearchResults(
                        searchText: viewModel.searchBarText,
                        numberOfSearchResults: viewModel.programmeSearchResults.count,
                        searchResults: viewModel.programmeSearchResults,
                        onOpenProgramme: openProgramme, 
                        universityImage: viewModel.universityImage
                    )
                case .error:
                    Info(
                        title: NSLocalizedString("Something went wrong", comment: ""), image: nil)
                case .empty:
                    Info(title: NSLocalizedString("Schedule is empty", comment: ""), image: nil)
                }
                SearchField(
                    search: search,
                    clearSearch: clearSearch,
                    title: "Search schedules",
                    searchBarText: $viewModel.searchBarText,
                    searching: $viewModel.searching,
                    disabled: $viewModel.schoolNotSelected
                )
                .blur(radius: viewModel.schoolNotSelected ? 2.5 : 0)
                .apply {
                    if #available(iOS 26.0, *) {
                        $0.padding(.horizontal, Spacing.small)
                    } else {
                        $0.padding(0)
                    }
                }
            }
            .padding([.horizontal, .bottom], Spacing.medium)
            .background(Color.background)
            .onChange(of: viewModel.selectedSchool) { school in
                if school == nil {
                    viewModel.schoolNotSelected = true
                } else {
                    viewModel.schoolNotSelected = false
                }
            }
            .fullScreenCover(item: $viewModel.searchPreviewModel) { model in
                SearchPreviewSheet(
                    viewModel: viewModel.searchPreviewViewModel,
                    programmeId: model.scheduleId,
                    schoolId: model.schoolId,
                    scheduleTitle: model.scheduleTitle,
                    closePreview: closePreview
                )
                .background(Color.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(NSLocalizedString("Search", comment: ""))
        }
        .tag(TabbarTabType.search)
    }
    
    /// Clear the previous preview model and
    /// set the state to loading upon next opening
    func closePreview() {
        viewModel.searchPreviewModel = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.searchPreviewViewModel.status = .loading
        }
    }

    fileprivate func searchBoxNotEmpty() -> Bool {
        return !viewModel.searchBarText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func search() {
        if let selectedSchool = viewModel.selectedSchool, searchBoxNotEmpty() {
            viewModel.universityImage = selectedSchool.logo
            viewModel.search(
                for: viewModel.searchBarText,
                selectedSchoolId: selectedSchool.id
            )
        }
    }
    
    func clearSearch() {
        withAnimation(.spring()) {
            viewModel.resetSearchResults()
        }
    }
    
    func openProgramme(programmeId: String, scheduleTitle: String) {
        if let selectedSchoolId = viewModel.selectedSchool?.id {
            viewModel.searchPreviewModel = SearchPreviewModel(
                scheduleId: programmeId, scheduleTitle: scheduleTitle.trimmingCharacters(in: .whitespacesAndNewlines), schoolId: String(selectedSchoolId)
            )
        }
    }
}
