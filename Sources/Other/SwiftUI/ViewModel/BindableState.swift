//
//  BindableState.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

@MainActor
protocol BindableState {
    associatedtype BindStateType = Void
    var bindings: BindStateType { get set }
}

extension BindableState where BindStateType == Void {
    var bindings: Void {
        get {}
        set {
            fatalError("Can't bind to the default Void binding.")
        }
    }
}
