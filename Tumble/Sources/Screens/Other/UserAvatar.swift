//
//  UserAvatar.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-21.
//

import SwiftUI

struct UserAvatar: View {
    let username: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary)
                .frame(width: .spacing5XL, height: .spacing5XL)
            
            Text(String(username.prefix(1)))
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.onPrimary)
        }
    }
}
