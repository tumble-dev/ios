//
//  SearchErrorView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/28/22.
//

import SwiftUI

struct SearchError: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 24))
                .padding(.bottom, Spacing.large)
            Text(NSLocalizedString("Looks like something went wrong", comment: ""))
                .font(.headline)
                .foregroundColor(.onBackground)
                .padding(.bottom, Spacing.extraLarge)
            Spacer()
        }
        .padding(.bottom, Spacing.small)
        .padding(.leading, Spacing.medium)
        .padding(.trailing, Spacing.medium)
    }
}
