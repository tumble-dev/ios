//
//  UIApplicationExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-30.
//

import Foundation
import StoreKit
import UIKit

extension UIApplication {
    /// Override variable
    private var keyWindow: UIWindow? {
        /// Get connected scenes
        return UIApplication.shared.connectedScenes
        /// Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
        /// Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
        /// Get its associated windows
            .flatMap { $0 as? UIWindowScene }?.windows
        /// Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
    /// Opens the default mail application on users
    /// phones and allows them to send an email to support
    func shareFeedback() {
        if let url = URL(string: "mailto:support@tumbleforkronox.com") {
            UIApplication.shared.open(url)
        }
    }
    
    func openGitHub() {
        if let url = URL(string: "https://github.com/tumble-for-kronox/Tumble-iOS") {
            UIApplication.shared.open(url)
        }
    }
    
    func openDiscord() {
        if let url = URL(string: "https://discord.gg/g4QQFuwRFT") {
            UIApplication.shared.open(url)
        }
    }
    
    func openBuyMeACoffee() {
        if let url = URL(string: "https://buymeacoffee.com/defaultdino") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens the App Store application with the review
    /// sheet already opened
    func openAppStoreForReview() {
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/1617642864?action=write-review")
        else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
}
