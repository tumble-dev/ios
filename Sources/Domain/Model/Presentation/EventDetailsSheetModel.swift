//
//  EventSheetModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-08.
//

import Foundation
import SwiftUI

struct EventDetailsSheetModel: Identifiable {
    var id: UUID = .init()
    let event: Event
}
