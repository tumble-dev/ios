//
//  DateGroup.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import Foundation

struct DateGroup: Identifiable {
    let id = UUID()
    let date: Date
    let events: [Response.Event]
}
