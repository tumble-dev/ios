//
//  Application.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/16/22.
//

import SwiftUI
import MijickPopupView

@main
struct Application: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openURL) private var openURL
    
    private var applicationCoordinator: ApplicationCoordinatorProtocol!
    
    init() {
        AppLogger.shared.info("[Application] In init()")
        applicationCoordinator = ApplicationCoordinator(appDelegate: appDelegate)
        SceneDelegate.windowManager = applicationCoordinator.windowManager
    }
    
    var body: some Scene {
        WindowGroup {
            applicationCoordinator
                .toPresentable()
                .implementPopupView()
                .environment(\.openURL, OpenURLAction { url in
                    if applicationCoordinator.handleDeepLink(url, isExternalURL: false) {
                        return .handled
                    }
                    return .systemAction
                })
                .onOpenURL { url in
                    openURL(url, isExternalURL: true)
                }
                .task {
                    AppLogger.shared.info("[Application] Calling applicationCoordinator.start()")
                    applicationCoordinator.start()
                }
        }
    }
    
    // MARK: - Private
    
    private func openURL(_ url: URL, isExternalURL: Bool) {
        if !applicationCoordinator.handleDeepLink(url, isExternalURL: isExternalURL) {
            openURLInSystemBrowser(url)
        }
    }
    
    private func openURLInSystemBrowser(_ originalURL: URL) {
        guard var urlComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: true) else {
            openURL(originalURL)
            return
        }
        
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(.init(name: "no_universal_links", value: "true"))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            openURL(originalURL)
            return
        }
        
        openURL(url)
    }
}
