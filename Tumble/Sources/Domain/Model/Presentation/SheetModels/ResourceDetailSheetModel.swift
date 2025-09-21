//
//  ResourceDetailSheetModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

struct ResourceDetailSheetModel: Identifiable {
    var id: UUID = .init()
    let resource: Response.KronoxUserBookingElement
}
