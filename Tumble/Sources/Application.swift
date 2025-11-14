//
//  Application.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/16/22.
//

import MijickPopupView
import SwiftUI

@main
struct Application: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openURL) private var openURL

    private var applicationCoordinator: ApplicationCoordinatorProtocol!

    init() {
        applicationCoordinator = ApplicationCoordinator(
            appDelegate: appDelegate
        )
        SceneDelegate.windowManager = applicationCoordinator.windowManager
        SceneDelegate.applicationCoordinator = applicationCoordinator as? ApplicationCoordinator
    }

    var body: some Scene {
        WindowGroup {
            applicationCoordinator
                .toPresentable()
                .implementPopupView()
                .environment(
                    \.openURL,
                    OpenURLAction { url in
                        if applicationCoordinator.handleDeepLink(
                            url,
                            isExternalURL: false
                        ) {
                            return .handled
                        }
                        return .systemAction
                    }
                )
                .onOpenURL { url in
                    openURL(url, isExternalURL: true)
                }
                .task {
                    applicationCoordinator.start()
                }
        }
    }

    // MARK: - Private

    private func openURL(_ url: URL, isExternalURL: Bool) {
        if !applicationCoordinator.handleDeepLink(
            url,
            isExternalURL: isExternalURL
        ) {
            // Don't try to open custom scheme URLs (like tumble://) externally
            // These should only be handled internally by the app
            if url.scheme == "tumble" {
                // Custom scheme URLs that weren't handled should be ignored
                return
            }
            
            // Only open actual web URLs externally
            openURLInSystemBrowser(url)
        }
    }

    private func openURLInSystemBrowser(_ originalURL: URL) {
        guard
            var urlComponents = URLComponents(
                url: originalURL,
                resolvingAgainstBaseURL: true
            )
        else {
            // If we can't parse the URL, open it directly with UIApplication
            UIApplication.shared.open(originalURL)
            return
        }

        var queryItems = urlComponents.queryItems ?? []
        
        // Check if no_universal_links is already present to avoid infinite recursion
        let hasNoUniversalLinks = queryItems.contains { $0.name == "no_universal_links" }
        
        if !hasNoUniversalLinks {
            queryItems.append(.init(name: "no_universal_links", value: "true"))
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            // If we can't construct the URL, open the original directly with UIApplication
            UIApplication.shared.open(originalURL)
            return
        }

        // Open with UIApplication instead of calling openURL again to avoid recursion
        UIApplication.shared.open(url)
    }
}
