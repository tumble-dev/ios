//
//  News.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-04.
//

import SwiftUI

struct News: View {
    let news: Response.NewsItems?
    @Binding var showOverlay: Bool
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.spring()) {
                    showOverlay = true
                }
            }, label: {
                HStack(alignment: .center) {
                    Text(
                        String(format: NSLocalizedString("News from us (%@)", comment: ""),
                               news != nil ? String(news!.count) : "0")
                    )
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.onPrimary)
                    Spacer()
                    Image(systemName: "newspaper")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.onPrimary)
                }
                .frame(maxWidth: .infinity)
            })
            .buttonStyle(WideAnimatedButtonStyle())
        }
        .padding(.bottom, Spacing.large)
        .frame(maxWidth: .infinity)
    }
}
