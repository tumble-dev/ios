//
//  ArrayExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-21.
//

import Foundation

extension Array {
    /// Chooses first n elements from an array
    func pick(from: Int = 0, length: Int) -> [Element] {
        precondition(length >= 0, "length must not be negative")
        if length >= count { return self }
        let oldMax = Double(count - from - 1)
        let newMax = Double(length - 1)
        return (0..<length).map { self[from + Int((Double($0) * oldMax / newMax).rounded())] }
    }
    
    /// This method takes an integer `size`
    /// and returns a two-dimensional array ([[Element]])
    /// where the original array is divided into chunks of the specified size.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
