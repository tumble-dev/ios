//
//  LoginHeader.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-12.
//

import SwiftUI

struct LoginHeader: View {
    let isAddAccount: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(NSLocalizedString(isAddAccount ? "Add account" : "Log in", comment: ""))
                .infoHeaderMedium()
                .padding(.leading, Spacing.medium)
            Text(NSLocalizedString(isAddAccount ? "You can later switch between your accounts" : "Please log in to continue", comment: ""))
                .infoBodyMedium(opacity: 0.75)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.medium)
    }
}

struct LoginHeader_Previews: PreviewProvider {
    static var previews: some View {
        LoginHeader(isAddAccount: true)
    }
}
