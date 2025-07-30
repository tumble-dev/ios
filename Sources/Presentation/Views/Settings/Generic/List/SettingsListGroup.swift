//
//  CustomListGroup.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-02.
//

import SwiftUI

struct SettingsListGroup<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, Spacing.small)
        .background(Color.surface)
        .cornerRadius(10)
        .padding(.horizontal, Spacing.medium)
        .padding(.top, Spacing.medium)
        .padding(.bottom, Spacing.large)
    }
}
