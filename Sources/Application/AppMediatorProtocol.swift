//
//  AppMediatorProtocol.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import Foundation
import UIKit

@MainActor
protocol AppMediatorProtocol {
    var windowManager: WindowManagerProtocol { get }
    var networkMonitor: NetworkMonitorProtocol { get }
    
    var appState: UIApplication.State { get }
    
    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
    
    func open(_ url: URL)
    
    func openAppSettings()
    
    func setIdleTimerDisabled(_ disabled: Bool)
}

extension UIApplication.State: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}

extension UIUserInterfaceActiveAppearance: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }
}
