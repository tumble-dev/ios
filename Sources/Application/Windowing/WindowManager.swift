//
//  WindowManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import SwiftUI

class WindowManager: WindowManagerProtocol {
    private let appDelegate: AppDelegate
    weak var windowScene: UIWindowScene?
    
    private(set) var mainWindow: UIWindow!
    private(set) var overlayWindow: UIWindow!
    private(set) var globalSearchWindow: UIWindow!
        
    var windows: [UIWindow] {
        [mainWindow, overlayWindow, globalSearchWindow]
    }
    
    // periphery:ignore - auto cancels when reassigned
    /// The task used to switch windows, so that we don't get stuck in the wrong state with a quick switch.
    @CancellableTask private var switchTask: Task<Void, Error>?
    /// A duration that allows window switching to wait a couple of frames to avoid a transition through black.
    private let windowHideDelay: TimeInterval = 0.033
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func configure(with windowScene: UIWindowScene) {
        self.windowScene = windowScene
        mainWindow = windowScene.keyWindow
        
        overlayWindow = PassthroughWindow(windowScene: windowScene)
        overlayWindow.backgroundColor = .clear
        overlayWindow.isHidden = false
        
        globalSearchWindow = UIWindow(windowScene: windowScene)
        globalSearchWindow.backgroundColor = .clear
        globalSearchWindow.isHidden = true
    }
    
    func switchToMain() {
        mainWindow.isHidden = false
        overlayWindow.isHidden = false
        
        mainWindow.makeKey()
    }
    
    func showGlobalSearch() {
        globalSearchWindow.isHidden = false
        globalSearchWindow.makeKey()
    }
    
    func hideGlobalSearch() {
        globalSearchWindow.isHidden = true
        mainWindow.makeKey()
    }
    
    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        if #available(iOS 16.0, *) {
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            // For iOS 15 and earlier, use the app delegate's orientation lock
            lockOrientation(orientation)
            
            // Force the orientation change by attempting to set the orientation
            if let _ = windowScene {
                let orientationToSet: UIInterfaceOrientation
                switch orientation {
                case .portrait:
                    orientationToSet = .portrait
                case .portraitUpsideDown:
                    orientationToSet = .portraitUpsideDown
                case .landscapeLeft:
                    orientationToSet = .landscapeLeft
                case .landscapeRight:
                    orientationToSet = .landscapeRight
                default:
                    orientationToSet = .unknown
                }
                
                if orientationToSet != .unknown {
                    // This is deprecated but necessary for iOS 15 support
                    UIDevice.current.setValue(orientationToSet.rawValue, forKey: "orientation")
                }
            }
        }
    }
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        appDelegate.orientationLock = orientation
    }
}

private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        
        guard let rootViewController else {
            return nil
        }
        
        guard hitView != self else {
            return nil
        }
        
        return rootViewController.view == hitView ? nil : hitView
    }
}
