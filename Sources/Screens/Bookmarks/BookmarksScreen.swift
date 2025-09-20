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
            placement: .toolbar,
            prompt: "Filter by title, course, or teacher"
        )
    }
    
    private var floatingSearchButton: some View {
        Button {
            context.send(viewAction: .showSearch)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.onSurface)
                .frame(width: 44, height: 44)
                .background(Color.surface, in: Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Browse programmes")
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
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                context.send(viewAction: .showAccount)
            } label: {
                Image(systemName: "person.crop.circle")
            }
            .accessibilityLabel("Settings")
        }
    }
}
