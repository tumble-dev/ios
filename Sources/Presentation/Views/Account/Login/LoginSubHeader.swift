//
//  LoginSubHeader.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-12.
//

import SwiftUI

struct LoginSubHeader: View {
    let schoolName: String
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            Text(String(format: NSLocalizedString("Use your university credentials for %@ to sign in to your KronoX account", comment: ""), schoolName))
                .font(.system(size: 16))
                .foregroundColor(.onSurface.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: {}) {
                Text(NSLocalizedString("Need help?", comment: ""))
                    .font(.system(size: 14))
                    .underline()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .ignoresSafeArea(.keyboard)
        .padding(.top, 35)
    }
}
