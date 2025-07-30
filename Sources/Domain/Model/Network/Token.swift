//
//  Token.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-17.
//

import Foundation

struct Token: Codable {
    let value: String
    let createdDate: Date
}

enum TokenType: String {
    case refreshToken = "refresh-token"
    case sessionDetails = "session-details"
}
