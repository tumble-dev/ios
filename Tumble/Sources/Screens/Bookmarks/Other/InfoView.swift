//
//  InfoViewType.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

// MARK: - Info View Types
enum InfoViewType {
    case empty(title: String, subtitle: String? = nil)
    case error(title: String, subtitle: String, retry: (() -> Void)? = nil)
    case loading(title: String? = "Loading...")
    case noConnection(retry: (() -> Void)? = nil)
    case custom(icon: String, title: String, subtitle: String? = nil, action: InfoViewAction? = nil)
}

struct InfoViewAction {
    let title: String
    let action: () -> Void
    let style: InfoViewActionStyle
}

enum InfoViewActionStyle {
    case primary
    case secondary
    case destructive
}

// MARK: - Info View Component
struct InfoView: View {
    let type: InfoViewType
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                iconView
                textContent
            }
            
            if type.action != nil {
                actionButton
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
    
    // MARK: - Icon View
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 80, height: 80)
            
            if type.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .onBackground))
                    .scaleEffect(1.2)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.onBackground)
            }
        }
    }
    
    // MARK: - Text Content
    @ViewBuilder
    private var textContent: some View {
        VStack(spacing: 8) {
            if let title = type.title {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.onBackground)
            }
            
            if let subtitle = type.subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.onBackground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Action Button
    @ViewBuilder
    private var actionButton: some View {
        if let action = type.action {
            Button(action: action.action) {
                HStack(spacing: 8) {
                    if action.title == "Try Again" {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    Text(action.title)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(buttonForegroundColor(for: action.style))
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(buttonBackgroundColor(for: action.style))
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Computed Properties
    private var iconName: String {
        switch type {
        case .empty:
            return "tray"
        case .error:
            return "exclamationmark.triangle"
        case .loading:
            return "clock"
        case .noConnection:
            return "wifi.slash"
        case .custom(let icon, _, _, _):
            return icon
        }
    }
    
    private var iconBackgroundColor: Color {
        Color.onBackground.opacity(0.1)
    }
    
    private func buttonBackgroundColor(for style: InfoViewActionStyle) -> Color {
        switch style {
        case .primary:
            return .primary
        case .secondary:
            return .surface
        case .destructive:
            return .red
        }
    }
    
    private func buttonForegroundColor(for style: InfoViewActionStyle) -> Color {
        switch style {
        case .primary, .destructive:
            return .onPrimary
        case .secondary:
            return .primary
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Type Extensions
extension InfoViewType {
    var title: String? {
        switch self {
        case .empty(let title, _):
            return title
        case .error(let title, _, _):
            return title
        case .loading(let title):
            return title
        case .noConnection:
            return "No Internet Connection"
        case .custom(_, let title, _, _):
            return title
        }
    }
    
    var subtitle: String? {
        switch self {
        case .empty(_, let subtitle):
            return subtitle
        case .error(_, let subtitle, _):
            return subtitle
        case .loading:
            return nil
        case .noConnection:
            return "Please check your internet connection and try again."
        case .custom(_, _, let subtitle, _):
            return subtitle
        }
    }
    
    var action: InfoViewAction? {
        switch self {
        case .empty:
            return nil
        case .loading:
            return nil
        case .custom(_, _, _, let action):
            return action
        case .error(_, _, let retry):
            return retry.map { InfoViewAction(title: "Try Again", action: $0, style: .primary) }
        case .noConnection(let retry):
            return retry.map { InfoViewAction(title: "Try Again", action: $0, style: .primary) }
        }
    }
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

// MARK: - Convenience Initializers
extension InfoView {
    static func empty(
        title: String,
        subtitle: String? = nil,
        action: InfoViewAction? = nil,
        icon: String = "tray"
    ) -> InfoView {
        InfoView(type: .custom(
            icon: icon,
            title: title,
            subtitle: subtitle,
            action: action
        ))
    }
    
    static func error(
        title: String = "Something went wrong",
        subtitle: String,
        retry: (() -> Void)? = nil
    ) -> InfoView {
        InfoView(type: .error(title: title, subtitle: subtitle, retry: retry))
    }
    
    static func loading(_ title: String = "Loading...") -> InfoView {
        InfoView(type: .loading(title: title))
    }
    
    static func noConnection(retry: (() -> Void)? = nil) -> InfoView {
        InfoView(type: .noConnection(retry: retry))
    }
}
