//
//  SectionDivie.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-15.
//

import SwiftUI

struct SectionDivider<Content: View>: View {
    let content: Content
    let title: String
    let image: String
    
    init(title: String, image: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.image = image
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: image)
                    .font(.system(size: 21))
                    .foregroundColor(.onBackground)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.onBackground)
                VStack(spacing: 0) {
                    Divider()
                        .overlay(Color.onBackground)
                        .padding([.leading, .trailing], 5)
                }
            }
            .padding(.bottom)
            content
        }
        .padding(Spacing.medium)
    }
}
