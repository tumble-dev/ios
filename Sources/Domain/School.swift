//
//  School.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//


import Foundation
import SwiftUI

struct School: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
    let logoPath: String
    
    init(id: String, name: String, color: Color, logoPath: String) {
        self.id = id
        self.name = name
        self.color = color
        self.logoPath = logoPath
    }
}
