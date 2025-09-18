//
//  SearchScreen.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI
import Combine

struct SearchScreen: View {
    @ObservedObject var context: SearchScreenViewModel.Context
    @State private var searchText: String = ""
    @State private var searching: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Search field at bottom
            SearchField(
                search: { performSearch() },
                clearSearch: { clearSearch() },
                title: "Search programmes...",
                searchBarText: $searchText,
                searching: $searching,
                disabled: .constant(context.viewState.selectedSchool == nil)
            )
            .padding()
        }
        .background(Color.background)
    }
    
    private var contentView: some View {
        Group {
            switch context.viewState.dataState {
            case .initial:
                SearchInfo(
                    schools: allSchools,
                    selectedSchool: Binding(
                        get: { context.viewState.selectedSchool },
                        set: { newValue in
                            if let newValue = newValue {
                                context.send(viewAction: .selectSchool(school: newValue))
                            } else {
                                context.send(viewAction: .changeSchool)
                            }
                        }
                    )
                )
                
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                
            case .loaded(let programmes):
                SearchResults(
                    searchText: searchText,
                    numberOfSearchResults: programmes.count,
                    searchResults: programmes,
                    onOpenProgramme: { programmeId, _ in
                        guard let selectedSchool = context.viewState.selectedSchool else { return }
                        context.send(viewAction: .openProgrammeEvents(programmeId: programmeId, school: selectedSchool.id))
                    },
                    universityImage: nil
                )
                
            case .empty:
                VStack {
                    Spacer()
                    Text("No programmes found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Try different search terms")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
            case .error(let message):
                VStack {
                    Spacer()
                    Text("Search failed")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try again") {
                        performSearch()
                    }
                    .padding(.top)
                    Spacer()
                }
            }
        }
    }
    
    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, context.viewState.selectedSchool != nil else { return }
        context.send(viewAction: .search(for: trimmed))
    }
    
    private func clearSearch() {
        context.send(viewAction: .clearSearch)
    }
}

struct SearchInfo: View {
    let schools: [School]
    @Binding var selectedSchool: School?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            if selectedSchool == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a university to begin your search")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)  // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }
            }
            
            FlowStack(items: schools) { school in
                SchoolPill(school: school, selectedSchool: $selectedSchool)
            }
            .padding(.horizontal)
        }
    }
}

struct SearchResults: View {
    let searchText: String
    let numberOfSearchResults: Int
    let searchResults: [Response.Programme]
    let onOpenProgramme: (String, String) -> Void
    let universityImage: Image?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(numberOfSearchResults) results")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults, id: \.id) { programme in
                        ProgrammeCard(
                            programme: programme,
                            universityImage: universityImage,
                            onOpenProgramme: onOpenProgramme
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct ProgrammeCard: View {
    let programme: Response.Programme
    let universityImage: Image?
    let onOpenProgramme: (String, String) -> Void
    
    var body: some View {
        Button(action: {
            onOpenProgramme(programme.id, programme.subtitle)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(programme.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        if let universityImage = universityImage {
                            universityImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .cornerRadius(2.5)
                        }
                        Text(programme.subtitle.trimmingCharacters(in: .whitespaces))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
