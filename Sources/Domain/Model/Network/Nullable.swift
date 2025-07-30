//
//  Nullable.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-27.
//

import Foundation

enum Nullable {
    // MARK: - Encode/decode helpers

    class JSONNull: Codable, Hashable {
        public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(0)
        }

        public init() {}

        public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                throw DecodingError.typeMismatch(
                    JSONNull.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}
