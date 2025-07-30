//
//  SearchPreviewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-05-28.
//

import Foundation

struct SearchPreviewModel: Identifiable {
    let id: UUID = .init()
    let scheduleId: String
    let scheduleTitle: String
    let schoolId: String
}
