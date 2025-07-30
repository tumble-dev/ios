//
//  UserAvatar.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-13.
//

import SwiftUI

struct UserAvatar: View {
    let name: String
    @Binding var collapsedHeader: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary)
                .frame(
                    width: collapsedHeader ? 65 : 95,
                    height: collapsedHeader ? 65 : 95
                )
            Text(name.abbreviate())
                .font(.system(size: collapsedHeader ? 25 : 36, weight: .semibold))
                .foregroundColor(.onPrimary)
        }
    }
}
