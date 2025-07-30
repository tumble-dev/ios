//
//  HomeAvailable.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-04.
//

import SwiftUI

struct HomeAvailable: View {
    @Binding var eventsForToday: [WeekEventCardModel]
    let nextClass: Event?
    @Binding var swipedCards: Int
    
    var body: some View {
        VStack(spacing: Spacing.extraLarge) {
            TodaysEvents(
                eventsForToday: $eventsForToday,
                swipedCards: $swipedCards
            )
            NextClass(nextClass: nextClass)
            Spacer()
        }
    }
}
