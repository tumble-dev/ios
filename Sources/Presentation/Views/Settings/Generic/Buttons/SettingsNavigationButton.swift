//
//  ListRowITem.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-02.
//

import SwiftUI

struct SettingsNavigationButton: View {
    let title: String
    let current: String?
    let leadingIcon: String
    let leadingIconBackgroundColor: Color
    let destination: AnyView
        
    init(
        title: String,
        current: String? = nil,
        leadingIcon: String,
        leadingIconBackgroundColor: Color,
        destination: AnyView
    ) {
        self.title = title
        self.current = current
        self.leadingIcon = leadingIcon
        self.leadingIconBackgroundColor = leadingIconBackgroundColor
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(destination: {
            destination
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }, label: {
            HStack {
                Label(title, systemImage: leadingIcon)
                    .labelStyle(ColorfulIconLabelStyle(color: leadingIconBackgroundColor))
                Spacer()
                if let current = current {
                    Text(current)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.onSurface.opacity(0.4))
                        .padding(.trailing, Spacing.medium)
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(.onSurface.opacity(0.4))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(Spacing.settingsButton)
        })
    }
}
