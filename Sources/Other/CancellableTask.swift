//
//  CancellableTask.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

@propertyWrapper
struct CancellableTask<S: Sendable, F: Error> {
    private var storedValue: Task<S, F>?
    
    init(_ value: Task<S, F>? = nil) {
        storedValue = value
    }
    
    var wrappedValue: Task<S, F>? {
        get {
            storedValue
        } set {
            storedValue?.cancel()
            storedValue = newValue
        }
    }
}
