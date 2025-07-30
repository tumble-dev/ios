//
//  InfoLoadingView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-01.
//

import SwiftUI

struct InfoLoading: View {
    let title: String
    var body: some View {
        VStack(alignment: .center) {
            CustomProgressIndicator()
                .padding(.bottom, Spacing.medium)
            Text(title)
                .infoBodyMedium()
                .multilineTextAlignment(.center)
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        )
        .background(Color.background)
    }
}
