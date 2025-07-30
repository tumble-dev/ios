//
//  WeekDays.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/23.
//

import SwiftUI

struct WeekDays: View {
    let days: [Day]?
    let weekDayDate: Date
    let toggleViewSwitcherVisibility: () -> Void
    
    var body: some View {
        Section(
            header: HStack {
                let dayName: String = "\(dateFormatterDay.string(from: weekDayDate)) \(dateFormatterDayMonth.string(from: weekDayDate))".capitalized
                Text(dayName)
                    .foregroundColor(.onBackground)
                    .font(.system(size: 18, weight: .semibold))
                Rectangle()
                    .fill(Color.onBackground)
                    .offset(x: 7.5)
                    .frame(height: 1)
                    .cornerRadius(20)
                Spacer()
                    .overlay {
                        if isLastDayOfWeek(dayName: dayName) {
                            Color.clear
                                .onAppear {
                                    withAnimation {
                                        toggleViewSwitcherVisibility()
                                    }
                                }
                                .onDisappear {
                                    withAnimation {
                                        toggleViewSwitcherVisibility()
                                    }
                                }
                        }
                    }
            },
            content: {
                if let days = days {
                    LazyVStack(spacing: Spacing.medium) {
                        ForEach(days, id: \.self) { day in
                            let sortedEvents = day.events.sorted(by: EventSorting.sortedEventOrder)
                            ForEach(sortedEvents, id: \.self) { event in
                                WeekEvent(event: event)
                            }
                        }
                    }
                } else {
                    EmptyEvent()
                }
            }
        )
        .padding(.vertical, Spacing.small)
    }
    
    fileprivate func isLastDayOfWeek(dayName: String) -> Bool {
        return dayName.components(separatedBy: " ").first == NSLocalizedString("Sunday", comment: "")
    }
}
