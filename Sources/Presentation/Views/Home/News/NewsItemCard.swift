//
//  NewsItemCard.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-05.
//

import SwiftUI

struct NewsItemCard: View {
    let newsItem: Response.NotificationContent
    
    @State private var detailsSheetOpen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(newsItem.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.onSurface)
                Spacer()
                Text(newsItem.timestamp.formatDate() ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.onSurface.opacity(0.8))
            }
            .padding(.bottom, Spacing.medium / 2)
            Text(newsItem.body)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.onSurface)
                .multilineTextAlignment(.leading)
        }
        .padding(Spacing.card)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .cornerRadius(15)
        .onTapGesture {
            HapticsController.triggerHapticLight()
            detailsSheetOpen = true
        }
        .sheet(isPresented: $detailsSheetOpen, content: {
            NewsItemDetails(newsItem: newsItem)
        })
    }
}
