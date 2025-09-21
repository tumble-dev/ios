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
                    icon: "bookmark.slash"
                )
                
            case .hidden:
                InfoView.empty(
                    title: "All bookmarks are hidden",
                    subtitle: "Your bookmarked events are currently filtered out. Adjust your settings to see them.",
                    action: InfoViewAction(
                        title: "Show Settings",
                        action: { context.send(viewAction: .showSettings) },
                        style: .primary
                    ),
                    icon: "eye.slash"
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
        }
        .toolbar { toolbar }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.background)
    }
    
    private func bookmarksListView(events: [Response.Event]) -> some View {
        let filteredEvents = filterEvents(events)
        
        return Group {
            if filteredEvents.isEmpty && !searchText.isEmpty {
                // No search results
                VStack(spacing: 20) {
                    InfoView.empty(
                        title: "No matching events",
                        subtitle: "No events match your search for \"\(searchText)\"",
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
    
    private func filterEvents(_ events: [Response.Event]) -> [Response.Event] {
        guard !searchText.isEmpty else { return events }
        
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return events.filter { event in
            if event.title.lowercased().contains(query) {
                return true
            }
            
            if event.id.lowercased().contains(query) {
                return true
            }
            
            if event.courseName.lowercased().contains(query) {
                return true
            }
            
            if event.courseId.lowercased().contains(query) {
                return true
            }
            
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
    
    // MARK: - Private
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            circularToolbarButton(
                systemName: "gearshape",
                accessibilityLabel: "Settings"
            ) {
                context.send(viewAction: .showSettings)
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            circularToolbarButton(
                systemName: "person.crop.circle",
                accessibilityLabel: "Account"
            ) {
                context.send(viewAction: .showAccount)
            }
        }
        
        ToolbarItem(placement: .bottomBar) {
            TextField("Filter events..", text: $searchText)
                .textFieldStyle(.automatic)
                .padding(.horizontal, 10)
        }
        
        
        ToolbarItem(placement: .bottomBar) {
            circularToolbarButton(
                systemName: "plus",
                accessibilityLabel: "Search"
            ) {
                context.send(viewAction: .showSearch)
            }
        }
    }
    
    private func circularToolbarButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundStyle(Color.onSurface)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.surface)
        .clipShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }
}
