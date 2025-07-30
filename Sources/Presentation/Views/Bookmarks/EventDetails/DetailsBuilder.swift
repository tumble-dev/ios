//
//  EventDetailsBodyBuilder.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-01.
//

import SwiftUI

struct DetailsBuilder<Content: View>: View {
    let title: String
    let image: String
    let content: Content
    
    init(title: String, image: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.image = image
        self.content = content()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.card) {
                HStack(alignment: .center, spacing: Spacing.small) {
                    Image(systemName: image)
                        .font(.system(size: 17))
                        .foregroundColor(.onSurface)
                    Text(title)
                        .font(.system(size: 17))
                        .bold()
                        .foregroundColor(.onBackground)
                }
                VStack(alignment: .leading) {
                    content
                }
            }
            Spacer()
        }
        .padding(Spacing.card)
        .background(Color.surface)
        .cornerRadius(15)
        .padding(.horizontal, Spacing.medium)
    }
}
