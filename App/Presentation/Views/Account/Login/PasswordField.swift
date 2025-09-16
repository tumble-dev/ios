//
//  PasswordField.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-12.
//

import SwiftUI

struct PasswordField: View {
    @Binding var password: String
    @FocusState private var isFocused: Bool
    @Binding var visiblePassword: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.onSurface.opacity(0.75))
                .padding(.trailing, 5)
            ZStack {
                TextField(NSLocalizedString("Password", comment: ""), text: $password)
                    .font(.system(size: 18))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .opacity(visiblePassword ? 1 : 0)
                    .keyboardType(.alphabet)
                    .foregroundColor(.onSurface)

                SecureField(NSLocalizedString("Password", comment: ""), text: $password)
                    .font(.system(size: 18))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .opacity(visiblePassword ? 0 : 1)
                    .foregroundColor(.onSurface)
            }
            Button(action: {
                visiblePassword.toggle()
            }) {
                Image(systemName: visiblePassword ? "eye" : "eye.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onSurface.opacity(0.75))
            }
            .buttonStyle(ScalingButtonStyle())
            Spacer()
        }
        .padding(Spacing.medium)
        .apply {
            if #available(iOS 26.0, *) {
                $0.glassEffect(.regular.interactive())
            } else {
                $0
                    .background(Color.surface)
                    .cornerRadius(15)
            }
        }
    }
}
