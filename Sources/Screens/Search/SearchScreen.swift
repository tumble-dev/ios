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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    context.send(viewAction: .close)
                }
            }
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
        ScrollView() {
            LazyVStack(spacing: 25) {
                ForEach(searchResults, id: \.id) { programme in
                    ProgrammeCard(
                        programme: programme,
                        universityImage: universityImage,
                        onOpenProgramme: onOpenProgramme
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
    }
}

struct ProgrammeCard: View {
    let programme: Response.Programme
    let universityImage: Image?
    let onOpenProgramme: (String, String) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            onOpenProgramme(programme.id, programme.subtitle)
        }) {
            HStack(spacing: 12) {
                // Programme Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(programme.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.onSurface)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(programme.subtitle.trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 14))
                        .foregroundColor(.onSurface)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Show programme ID if it's not blank and not contained in title
                    if !programme.id.isEmpty &&
                       !programme.title.localizedCaseInsensitiveContains(programme.id) {
                        Text(programme.id)
                            .font(.system(size: 12))
                            .foregroundColor(.onSurface.opacity(0.9))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Chevron Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.onSurface.opacity(0.6))
                    .frame(width: 20, height: 20)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.secondary)
            .cornerRadius(12)
            .shadow(
                color: .black.opacity(isPressed ? 0.1 : 0.05),
                radius: isPressed ? 4 : 1,
                x: 0,
                y: isPressed ? 2 : 0.5
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
