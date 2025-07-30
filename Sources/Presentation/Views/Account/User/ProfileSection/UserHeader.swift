//
//  UserHeader.swift
//  App
//
//  Created by Timur Ramazanov on 08.12.2024.
//

import SwiftUI

struct UserHeader: View {
    @Binding var collapsedHeader: Bool
    @ObservedObject var viewModel: AccountViewModel
    
    var body: some View {
        HStack(spacing: Spacing.small) {
            if let name = viewModel.userDisplayName,
               let username = viewModel.username
            {
                UserAvatar(name: name, collapsedHeader: $collapsedHeader)
                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.system(size: collapsedHeader ? 20 : 22, weight: .semibold))
                    if !collapsedHeader {
                        Text(username)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.onSurface.opacity(0.8))
                            .padding(.top, Spacing.extraSmall)
                        Text(viewModel.schoolName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.onSurface.opacity(0.8))
                    }
                    Text(NSLocalizedString(viewModel.users.count > 1 ? "Change account" : "Add account", comment: ""))
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, Spacing.small)
                }
                .padding(.leading, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
