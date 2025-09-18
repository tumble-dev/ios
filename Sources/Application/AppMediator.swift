//
//  AppMediator.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import AVFoundation
import UIKit

class AppMediator: AppMediatorProtocol {
    let windowManager: WindowManagerProtocol
    let networkMonitor: NetworkMonitorProtocol
    
    init(windowManager: WindowManagerProtocol, networkMonitor: NetworkMonitorProtocol) {
        self.windowManager = windowManager
        self.networkMonitor = networkMonitor
    }
        
    // UIApplication.State won't update if we store this e.g. in the constructor
    private var application: UIApplication {
        UIApplication.shared
    }

    var appState: UIApplication.State {
        switch application.applicationState {
        case .active:
            windowManager.mainWindow.traitCollection.activeAppearance == .active ? .active : .inactive
        case .inactive:
            .inactive
        case .background:
            .background
        default:
            .inactive
        }
    }
    
    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        application.beginBackgroundTask(expirationHandler: handler)
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        application.endBackgroundTask(identifier)
    }
    
    func open(_ url: URL) {
        application.open(url, options: [:], completionHandler: nil)
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        open(url)
    }
    
    func setIdleTimerDisabled(_ disabled: Bool) {
        application.isIdleTimerDisabled = disabled
    }
}
