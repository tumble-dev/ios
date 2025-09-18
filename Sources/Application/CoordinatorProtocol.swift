//
//  CoordinatorProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import SwiftUI

@MainActor
protocol CoordinatorProtocol: AnyObject {
    func start()
    func stop()
    func toPresentable() -> AnyView
}

extension CoordinatorProtocol {
    func start() { }
    func stop() { }
    func toPresentable() -> AnyView {
        AnyView(Text("View not configured"))
    }
}
