//
//  SceneDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    weak static var windowManager: WindowManager!
    weak static var applicationCoordinator: ApplicationCoordinator!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Self.windowManager.configure(with: windowScene)
        
        // Handle any URLs that were used to launch the app
        if let url = connectionOptions.urlContexts.first?.url {
            _ = Self.applicationCoordinator.handleDeepLink(url, isExternalURL: true)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = Self.applicationCoordinator.handleDeepLink(url, isExternalURL: true)
    }
}
