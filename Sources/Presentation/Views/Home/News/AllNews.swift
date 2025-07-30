//
//  AllNews.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-05.
//

import SwiftUI

struct AllNews: View {
    let news: Response.NewsItems?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(NSLocalizedString("Other news", comment: ""))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.onBackground)
                Spacer()
            }
            if let news = news {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    if news.count >= 4 {
                        if news[4...].isEmpty {
                            Text(NSLocalizedString("No other news", comment: ""))
                                .font(.system(size: 16))
                                .foregroundColor(.onBackground)
                                .padding(.top, Spacing.medium / 2)
                        } else {
                            ForEach(news[4...], id: \.self) { newsItem in
                                NewsItemCard(newsItem: newsItem)
                            }
                        }
                    } else {
                        Text(NSLocalizedString("No other news", comment: ""))
                            .font(.system(size: 16))
                            .foregroundColor(.onBackground)
                            .padding(.top, Spacing.medium / 2)
                    }
                }
            }
        }
        .padding(.top, Spacing.medium * 2)
    }
}
