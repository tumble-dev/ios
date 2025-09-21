//
//  School.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/16/22.
//

import Foundation
import SwiftUI

struct School: Hashable, Codable, Identifiable, Equatable {
    let id: Int
    let kronoxUrl: String
    let name: String
    let loginRq: Bool
    let color: String
    let schoolUrl: String
    let domain: String
    
    private var logoName: String
    var logo: Image {
        Image(logoName)
    }
}
