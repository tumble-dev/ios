//
//  LoginButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-12.
//

import SwiftUI

struct LoginButton: View {
    let login: () -> Void
    @Binding var username: String
    @Binding var password: String
    
    var body: some View {
        Button(action: login, label: {
            HStack {
                Text(NSLocalizedString("Log in", comment: ""))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onPrimary)
            }
        })
        .disabled(emptyCredentials())
        .buttonStyle(WideAnimatedButtonStyle())
        .ignoresSafeArea(.keyboard)
    }
    
    fileprivate func emptyCredentials() -> Bool {
        return username.isEmpty || password.isEmpty
    }
}
