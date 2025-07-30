//
//  EventSorting.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/23.
//

import Foundation

struct EventSorting {
    static func sortedEventOrder(event1: Event, event2: Event) -> Bool {
        guard let firstDate = Calendar.current.date(from: event1.dateComponents!),
             let secondDate = Calendar.current.date(from: event2.dateComponents!) else {
           return false
       }
       return firstDate < secondDate
    }
}
