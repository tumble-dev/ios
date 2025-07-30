//
//  WeekEventCardModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/7/23.
//

import Foundation

struct WeekEventCardModel: Identifiable {
    var id: UUID = .init()
    var offset: CGFloat = 0
    var event: Event
}
