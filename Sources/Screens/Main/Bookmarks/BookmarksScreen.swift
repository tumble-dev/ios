//
//  BookmarksView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI
import Combine

struct BookmarksScreen: View {
    @ObservedObject var context: BookmarksScreenViewModel.Context
    @State private var searchText = ""
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            switch context.viewState.dataState {
            case .empty:
                InfoView.empty(
                    title: "No bookmarks yet",
                    subtitle: "Events you bookmark will appear here for quick access",
                    action: InfoViewAction(
                        title: "Browse Events",
                        action: { context.send(viewAction: .showSearch) },
                        style: .primary
                    )
                )
                
            case .hidden:
                InfoView.empty(
                    title: "All bookmarks are hidden",
                    subtitle: "Your bookmarked events are currently filtered out. Adjust your settings to see them.",
                    action: InfoViewAction(
                        title: "Show Settings",
                        action: { context.send(viewAction: .showSettings) },
                        style: .primary
                    )
                )
                
            case .loading:
                InfoView.loading("Loading bookmarks...")
                
            case .error(let msg):
                InfoView.error(
                    subtitle: msg,
                    retry: { }
                )
                
            case .loaded(let events):
                bookmarksListView(events: events)
            }
            
            // Only show floating search button when there's content and no active search
            if case .loaded = context.viewState.dataState, searchText.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingSearchButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .toolbar { toolbar }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.background)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by title, course, teacher, or ID"
        )
    }
    
    private func bookmarksListView(events: [Response.Event]) -> some View {
        let filteredEvents = filterEvents(events)
        
        return Group {
            if filteredEvents.isEmpty && !searchText.isEmpty {
                // No search results
                VStack(spacing: 20) {
                    InfoView.empty(
                        title: "No matching bookmarks",
                        subtitle: "No bookmarks match your search for \"\(searchText)\"",
                        action: InfoViewAction(
                            title: "Clear Search",
                            action: { searchText = "" },
                            style: .secondary
                        )
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Search results header
                        if !searchText.isEmpty {
                            searchResultsHeader(
                                totalCount: events.count,
                                filteredCount: filteredEvents.count
                            )
                        }
                        
                        let groupedEvents = filteredEvents.groupByDate()
                        ForEach(groupedEvents, id: \.date) { dateGroup in
                            // Date Header
                            DateSectionHeader(date: dateGroup.date)
                                .padding(.horizontal, 16)
                                .padding(.top, dateGroup.date == groupedEvents.first?.date ? (searchText.isEmpty ? 0 : 8) : 24)
                            
                            // Events for this date
                            ForEach(dateGroup.events, id: \.id) { event in
                                EventCard(event: event)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .onTapGesture {
                                        context.send(viewAction: .openEvent(eventId: event.id))
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func searchResultsHeader(totalCount: Int, filteredCount: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(filteredCount) of \(totalCount) event\(totalCount == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundColor(.onBackground)
                
                Text("matching \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundColor(.onBackground)
            }
            
            Spacer()
            
            Button("Clear") {
                searchText = ""
            }
            .font(.subheadline)
            .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func filterEvents(_ events: [Response.Event]) -> [Response.Event] {
        guard !searchText.isEmpty else { return events }
        
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return events.filter { event in
            // Search in title
            if event.title.lowercased().contains(query) {
                return true
            }
            
            // Search in event ID
            if event.id.lowercased().contains(query) {
                return true
            }
            
            // Search in course name
            if event.courseName.lowercased().contains(query) {
                return true
            }
            
            // Search in course ID
            if event.courseId.lowercased().contains(query) {
                return true
            }
            
            // Search in teacher names
            for teacher in event.teachers {
                let fullName = "\(teacher.firstName) \(teacher.lastName)".lowercased()
                let firstName = teacher.firstName.lowercased()
                let lastName = teacher.lastName.lowercased()
                
                if fullName.contains(query) || firstName.contains(query) || lastName.contains(query) {
                    return true
                }
            }
            
            return false
        }
    }
    
    private var floatingSearchButton: some View {
        Button {
            context.send(viewAction: .showSearch)
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.primary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Search programmes")
    }
    
    // MARK: - Private
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }
}
