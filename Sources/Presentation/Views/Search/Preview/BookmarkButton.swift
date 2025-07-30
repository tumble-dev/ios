//
//  BookmarkButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import SwiftUI

struct BookmarkButton: View {
    let bookmark: () -> Void
    @Binding var buttonState: ButtonState
    @Namespace private var buttonNamespace
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            withAnimation(.spring()) {
                bookmark()
            }
        }) {
            HStack {
                switch buttonState {
                case .loading, .disabled:
                    CustomProgressIndicator(color: .onPrimary)
                        .padding(Spacing.small)
                        .matchedGeometryEffect(id: "progressIndicator", in: buttonNamespace)
                case .saved:
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.onPrimary)
                            .matchedGeometryEffect(id: "bookmarkIcon", in: buttonNamespace)
                        Text(NSLocalizedString("Remove", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.onPrimary)
                            .matchedGeometryEffect(id: "bookmarkText", in: buttonNamespace)
                    }
                case .notSaved:
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 16))
                            .foregroundColor(.onPrimary)
                            .matchedGeometryEffect(id: "bookmarkIcon", in: buttonNamespace)
                        Text(NSLocalizedString("Save", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.onPrimary)
                            .matchedGeometryEffect(id: "bookmarkText", in: buttonNamespace)
                    }
                }
            }
        }
        .buttonStyle(PillStyle(color: .primary))
        .padding(.leading, Spacing.medium)
        .padding(.top, Spacing.extraSmall)
    }
}
