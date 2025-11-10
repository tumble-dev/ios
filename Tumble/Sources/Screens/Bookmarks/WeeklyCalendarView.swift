//
//  WeeklyCalendarView.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-10.
//

import SwiftUI

struct WeeklyCalendarView: View {
    let events: [Response.Event]
    let onEventTap: (String) -> Void
    
    @State private var currentWeekOffset: Int = 0
    @State private var selectedDate: Date = Date()
    @GestureState private var dragOffset: CGFloat = 0
    
    private let calendar = Calendar.current
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Week navigation header
                weekHeader
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                Divider()
                
                // Week days header
                weekDaysHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                // Swipeable week view
                TabView(selection: $currentWeekOffset) {
                    ForEach(-52...52, id: \.self) { offset in
                        weekView(for: offset, geometry: geometry)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentWeekOffset) { _ in
                    updateSelectedDate()
                }
            }
        }
        .onAppear {
            updateSelectedDate()
        }
    }
    
    // MARK: - Week Header
    
    private var weekHeader: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.onSurface)
            }
            
            Spacer()
            
            Text(weekRangeText)
                .font(.headline)
                .foregroundColor(.onSurface)
            
            Spacer()
            
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.onSurface)
            }
        }
    }
    
    private var weekRangeText: String {
        let weekDates = getWeekDates(for: currentWeekOffset)
        guard let firstDay = weekDates.first, let lastDay = weekDates.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let firstString = formatter.string(from: firstDay)
        formatter.dateFormat = "d, yyyy"
        let lastString = formatter.string(from: lastDay)
        
        return "\(firstString) - \(lastString)"
    }
    
    // MARK: - Week Days Header
    
    private var weekDaysHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.onSurface.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Week View
    
    private func weekView(for offset: Int, geometry: GeometryProxy) -> some View {
        let weekDates = getWeekDates(for: offset)
        let weekEvents = getEventsForWeek(weekDates)
        
        return ScrollView {
            VStack(spacing: 0) {
                // Date selector
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        dateCell(for: date)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Events for selected date
                let dayEvents = weekEvents[calendar.startOfDay(for: selectedDate)] ?? []
                
                if dayEvents.isEmpty {
                    VStack {
                        Spacer()
                        InfoView.empty(
                            title: "No events",
                            subtitle: "No bookmarked events on \(formattedDate(selectedDate))",
                            icon: "calendar"
                        )
                        Spacer()
                    }
                    .frame(height: geometry.size.height * 0.5)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(dayEvents.sorted { $0.from < $1.from }, id: \.id) { event in
                            EventCard(event: event)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .onTapGesture {
                                    onEventTap(event.id)
                                }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // MARK: - Date Cell
    
    private func dateCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)
        let hasEvents = !getEventsForDate(date).isEmpty
        
        return VStack(spacing: 4) {
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .onPrimary : (isToday ? .primary : .onSurface))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.primary : (isToday ? Color.primary.opacity(0.1) : Color.clear))
                )
            
            // Event indicator
            if hasEvents {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getWeekDates(for offset: Int) -> [Date] {
        let today = Date()
        guard let targetWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: today) else {
            return []
        }
        
        // Get Monday of the target week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: targetWeek)
        components.weekday = 2 // Monday
        
        guard let monday = calendar.date(from: components) else {
            return []
        }
        
        // Generate all 7 days of the week
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monday)
        }
    }
    
    private func getEventsForWeek(_ weekDates: [Date]) -> [Date: [Response.Event]] {
        var eventsByDate: [Date: [Response.Event]] = [:]
        
        for date in weekDates {
            let startOfDay = calendar.startOfDay(for: date)
            eventsByDate[startOfDay] = []
        }
        
        for event in events {
            let eventDate = calendar.startOfDay(for: event.from)
            if weekDates.contains(where: { calendar.isDate($0, inSameDayAs: eventDate) }) {
                eventsByDate[eventDate, default: []].append(event)
            }
        }
        
        return eventsByDate
    }
    
    private func getEventsForDate(_ date: Date) -> [Response.Event] {
        let startOfDay = calendar.startOfDay(for: date)
        return events.filter { event in
            calendar.isDate(event.from, inSameDayAs: startOfDay)
        }
    }
    
    private func updateSelectedDate() {
        let weekDates = getWeekDates(for: currentWeekOffset)
        
        // If current selected date is not in the new week, select the first day with events
        if !weekDates.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) {
            // Try to find a day with events
            if let dayWithEvents = weekDates.first(where: { !getEventsForDate($0).isEmpty }) {
                selectedDate = dayWithEvents
            } else {
                // Otherwise, select Monday (first day)
                selectedDate = weekDates.first ?? Date()
            }
        }
    }
    
    private func previousWeek() {
        withAnimation {
            currentWeekOffset -= 1
        }
    }
    
    private func nextWeek() {
        withAnimation {
            currentWeekOffset += 1
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
