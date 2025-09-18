//
//  SceneDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    weak static var windowManager: WindowManager!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Self.windowManager.configure(with: windowScene)
    }
}
