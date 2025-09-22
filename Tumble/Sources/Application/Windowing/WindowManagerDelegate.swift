//
//  WindowManagerDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import SwiftUI

/// Heavily inspired by https://www.fivestars.blog/articles/swiftui-windows
@MainActor
protocol WindowManagerProtocol: AnyObject, WindowManager {
    var mainWindow: UIWindow! { get }
    var overlayWindow: UIWindow! { get }
    
    func configure(with windowScene: UIWindowScene)
    func switchToMain()
    
    var windows: [UIWindow] { get }
}
