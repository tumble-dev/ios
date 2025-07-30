//
//  PopupToast.swift
//  Tumble
//
//  Created by Adis Veletanlic on 7/15/23.
//

import SwiftUI
import MijickPopupView

struct PopupToast: BottomPopup {
    
    let popup: Popup
    
    func createContent() -> some View {
        HStack {
            VStack (alignment: .leading, spacing: 0) {
                Text(popup.title)
                    .foregroundColor(.onPrimary)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.bottom, 5)
                if let message = popup.message {
                    Text(message)
                        .foregroundColor(.onPrimary)
                        .font(.system(size: 13, weight: .regular))
                }
            }
            Spacer()
            Image(systemName: popup.leadingIcon)
                .foregroundColor(.onPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Color.primary)
        .cornerRadius(10.0)
        .padding(Spacing.medium)
        .padding(.bottom, 40)
    }
    
    func configurePopup(popup: BottomPopupConfig) -> BottomPopupConfig {
        popup
            .tapOutsideToDismiss(true)
            .backgroundColour(.black.opacity(0))
    }
}
