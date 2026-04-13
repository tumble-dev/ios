//
//  FlowCoordinatorProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

@MainActor
protocol FlowCoordinatorProtocol {
    func start()
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool)
    func clearRoute(animated: Bool)
}
