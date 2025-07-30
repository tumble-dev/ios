//
//  CalendarView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-18.
//

import Foundation
import FSCalendar
import SwiftUI

struct BookmarkCalendarView: View {
    @ObservedObject var appController: AppController
    
    @State private var selectedDateEvents: [Event] = .init()
    @State private var selectedDate: Date = .init()
    var calendarEventsByDate: [Date: [Event]]
    var days: [Day]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            CalendarViewRepresentable(
                selectedDate: $selectedDate,
                selectedDateEvents: $selectedDateEvents,
                calendarEventsByDate: calendarEventsByDate
            )
            .id(days)
            .onChange(of: days) { _ in
                selectedDate = Date.now
                updateDisplayedDayEvents(for: selectedDate)
            }
            .frame(height: 375)
            
            VStack {
                if selectedDateEvents.isEmpty {
                    HStack {
                        Spacer()
                        Text(NSLocalizedString("No events for this date", comment: ""))
                            .foregroundColor(.onBackground)
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                    }
                    .padding(.top, Spacing.extraLarge)
                    .padding(.horizontal, Spacing.medium)
                } else {
                    LazyVStack(spacing: Spacing.medium) {
                        let sortedDateEvents = selectedDateEvents.sorted()
                        ForEach(sortedDateEvents, id: \.self) { event in
                            BookmarkCalendarDetail(
                                onTapDetail: onTapDetail,
                                event: event
                            )
                        }
                    }
                    .padding(.bottom, Spacing.extraLarge*2)
                    .padding(.top, Spacing.medium)
                }
            }
        }
        .onFirstAppear {
            updateDisplayedDayEvents(for: selectedDate)
        }
    }
    
    private func onTapDetail(event: Event) {
        appController.eventSheet = EventDetailsSheetModel(event: event)
    }
    
    private func updateDisplayedDayEvents(for date: Date) {
        selectedDateEvents = days.filter { day in
            let dayDate = isoDateFormatterFract.date(from: day.isoString) ?? Date()
            return Calendar.current.isDate(dayDate, inSameDayAs: date) && day.isValidDay()
        }.flatMap { $0.events }.removeDuplicates()
    }
}

