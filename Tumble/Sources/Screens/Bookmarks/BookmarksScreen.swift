//
//  BookmarksScreen.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import FSCalendar
import SwiftUI

struct BookmarksScreen: View {
    @ObservedObject var context: BookmarksScreenViewModel.Context
    @State private var searchText = ""
    @State private var selectedDate: Date = .now
    @State private var selectedDateEvents: [Response.Event] = []
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
                    retry: {}
                )
                
            case .loaded(let events):
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad: Always show daily list in sidebar
                    bookmarksDailyView(events: events)
                } else {
                    // iPhone: Show selected view type
                    switch context.viewState.bookmarksViewType {
                    case .daily: bookmarksDailyView(events: events)
                    case .monthly: bookmarksMonthlyView(events: events)
                    case .weekly: bookmarksWeeklyView(events: events)
                    }
                }
            }
        }
        .toolbar { toolbar }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(UIDevice.current.userInterfaceIdiom == .pad ? .large : .inline)
        .background(Color.background)
        .tint(.primary)
    }
    
    private func bookmarksWeeklyView(events: [Response.Event]) -> some View {
        WeeklyCalendarView(
            events: events,
            onEventTap: { eventId in
                context.send(viewAction: .openEvent(eventId: eventId))
            }
        )
    }
    
    private func bookmarksMonthlyView(events: [Response.Event]) -> some View {
        // Group events by date for the calendar
        let eventsByDate = Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.from)
        }.mapValues { $0 }
        
        return GeometryReader { geometry in
            VStack(spacing: 0) {
                // Calendar View
                CalendarViewRepresentable(
                    selectedDate: $selectedDate,
                    selectedDateEvents: $selectedDateEvents,
                    calendarEventsByDate: eventsByDate
                )
                .frame(height: 400)
                
                // Divider
                Divider()
                    .padding(.vertical, 8)
                
                // Events for selected date
                if selectedDateEvents.isEmpty {
                    VStack {
                        Spacer()
                        InfoView.empty(
                            title: "No events",
                            subtitle: "No bookmarked events on \(formattedDate(selectedDate))",
                            icon: "calendar"
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Events
                            ForEach(selectedDateEvents.sorted { $0.from < $1.from }, id: \.id) { event in
                                EventCard(event: event)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .onTapGesture {
                                        context.send(viewAction: .openEvent(eventId: event.id))
                                    }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func bookmarksDailyView(events: [Response.Event]) -> some View {
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
                .refreshable {
                    await loadHistoricalEvents()
                }
            }
        }
    }
    
    private func loadHistoricalEvents() async {
        context.send(viewAction: .loadHistoricalEvents)
        
        // Give a small delay to show the refresh animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
        
        ToolbarItem(placement: .topBarTrailing) {
            if UIDevice.current.userInterfaceIdiom != .pad {
                viewTypeMenu
            }
        }
        
        // Only show search in daily view
        ToolbarItem(placement: .bottomBar) {
            Group {
                if context.viewState.bookmarksViewType == .daily {
                    TextField("Filter events..", text: $searchText)
                        .textFieldStyle(.automatic)
                        .padding(.horizontal, 10)
                } else {
                    EmptyView()
                }
            }
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
    
    private var viewTypeMenu: some View {
        Menu {
            Button {
                context.send(viewAction: .changeViewType(.daily))
            } label: {
                if context.viewState.bookmarksViewType == .daily {
                    Label("Daily", systemImage: "checkmark")
                } else {
                    Text("Daily")
                }
            }
            
            Button {
                context.send(viewAction: .changeViewType(.monthly))
            } label: {
                if context.viewState.bookmarksViewType == .monthly {
                    Label("Monthly", systemImage: "checkmark")
                } else {
                    Text("Monthly")
                }
            }
            
            Button {
                context.send(viewAction: .changeViewType(.weekly))
            } label: {
                if context.viewState.bookmarksViewType == .weekly {
                    Label("Weekly", systemImage: "checkmark")
                } else {
                    Text("Weekly")
                }
            }
        } label: {
            Image(systemName: viewTypeIcon)
                .foregroundStyle(Color.onSurface)
        }
        .buttonStyle(.borderedProminent)
        .tint(.primary)
        .clipShape(Circle())
        .accessibilityLabel("Change view type")
    }
    
    private var viewTypeIcon: String {
        switch context.viewState.bookmarksViewType {
        case .daily:
            return "list.bullet"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar"
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
