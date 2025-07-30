//
//  UserOptionView.swift
//  App
//
//  Created by Timur Ramazanov on 08.12.2024.
//

import SwiftUI

struct UserOptionView: View {
    let user: TumbleUser
    let viewModel: AccountViewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(user.name) (\(viewModel.schools.first(where: { $0.id == user.schoolId })?.domain.uppercased() ?? ""))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onSurface)
                Spacer()
                if viewModel.currentUser == user.username {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.onSurface)
                }
            }
            .foregroundColor(.onBackground)
            .padding(.vertical, Spacing.extraSmall)
        }
    }
}
