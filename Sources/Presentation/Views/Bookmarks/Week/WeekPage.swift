//
//  WeekPage.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/23.
//

import SwiftUI

struct WeekPage: View {
    let weekStart: Date
    let weekDays: [Day]
    let toggleViewSwitcherVisibility: () -> Void
    
    var body: some View {
        let weekOfYear = weekStart.get(.weekOfYear)
        let daysForWeek = weekDays.normalizedToWeekDays()

        ScrollView (showsIndicators: false) {
            LazyVStack {
                HStack {
                    Spacer()
                    Text(String(format: NSLocalizedString("w. %@", comment: ""), "\(weekOfYear)"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.onBackground)
                }

                if weekDays.isEmpty {
                    VStack {
                        Text(NSLocalizedString("No events for this week..", comment: ""))
                            .foregroundColor(.onBackground)
                            .infoBodyMedium()
                        Image("GirlRelaxing")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 175)
                            .padding(.top, Spacing.medium)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.top, 30)
                } else {
                    ForEach(1...7, id: \.self) { dayOfWeek in
                        let weekDayDate = gregorianCalendar.date(byAdding: .day, value: dayOfWeek - 1, to: weekStart)!
                        WeekDays(
                            days: daysForWeek[dayOfWeek],
                            weekDayDate: weekDayDate,
                            toggleViewSwitcherVisibility: toggleViewSwitcherVisibility
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding([.top, .horizontal], Spacing.medium)
            .apply {
                if #available(iOS 26.0, *) {
                    $0.padding(.bottom, 75)
                } else {
                    $0.padding(.bottom, Spacing.extraLarge)
                }
            }
        }
    }
}
