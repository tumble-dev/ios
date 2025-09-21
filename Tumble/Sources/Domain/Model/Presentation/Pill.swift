//
//  SchoolPill.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-05-24.
//

import Foundation
import SwiftUI

protocol Pill: Identifiable, Hashable {
    var title: String { get }
    var icon: Image { get }
    var id: UUID { get }
}

extension Pill {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
