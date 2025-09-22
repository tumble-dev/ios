//
//  ApplicationCoordinatorProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

@MainActor
protocol ApplicationCoordinatorProtocol: CoordinatorProtocol {
    var windowManager: WindowManagerProtocol { get }
    
    @discardableResult func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool
}
