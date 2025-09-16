//
//  NewsItemDetails.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-05.
//

import SwiftUI

struct NewsItemDetails: View {
    let newsItem: Response.NotificationContent
    @Environment(\.dismiss) var dismiss
    
    func close() -> Void {
        dismiss()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                if (!newsItem.topic.isEmpty) {
                    Text(newsItem.topic.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.onPrimary)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.extraSmall)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 100))
                }
                VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                    if let date = isoDateFormatter.date(from: newsItem.timestamp) {
                        Text(localizedLongDateFormatter.string(from: date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.onBackground.opacity(0.8))
                    }
                    Text(newsItem.title)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.onBackground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Spacing.small)
            Text(newsItem.body)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.onBackground)
                .padding(Spacing.medium)
                .background(Color.surface)
                .cornerRadius(15)
            Spacer()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.top, Spacing.header)
        .background(Color.background)
        .overlay(
            CloseCoverButton(onClick: close),
            alignment: .topTrailing
        )
        .overlay(
            Text(NSLocalizedString("Details", comment: ""))
                .sheetTitle(),
            alignment: .top
        )
    }
}
