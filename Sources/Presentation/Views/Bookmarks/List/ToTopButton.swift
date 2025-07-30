//
//  ToTopButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-02.
//

import SwiftUI

struct ToTopButton: View {
    var proxy: ScrollViewProxy
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticMedium()
            withAnimation(.spring()) {
                proxy.scrollTo("bookmarkScrollView", anchor: .top)
            }
        }, label: {
            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.onPrimary)
                .padding(13)
                .frame(maxWidth: 38, maxHeight: 38)
        })
        .buttonStyle(ToTopButtonStyle())
    }
}
