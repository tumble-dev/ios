//
//  EventDetailSheetModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

struct ExamDetailSheetModel: Identifiable {
    var id: UUID = .init()
    let event: Response.AvailableKronoxUserEvent
}
