//
//  Bookmark.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Foundation

class Bookmark: Identifiable, ObservableObject {
    @Published var toggled: Bool
    let id: String
    
    init(toggled: Bool, id: String) {
        self.toggled = toggled
        self.id = id
    }
    
    private enum CodingKeys: String, CodingKey {
        case toggled
        case id
    }
}
