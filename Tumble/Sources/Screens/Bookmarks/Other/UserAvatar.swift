//
//  UserAvatar.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-21.
//

import SwiftUI

struct UserAvatar: View {
    let name: String
    let size: CGFloat
    
    init(name: String, size: CGFloat = 32) {
        self.name = name
        self.size = size
    }
    
    private var initials: String {
        let components = name.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if components.count >= 2 {
            // Take first letter of first and last name
            return String(components.first!.prefix(1) + components.last!.prefix(1))
        } else if let first = components.first {
            // Take first two letters of single name
            return String(first.prefix(2))
        }
        return "?"
    }
    
    var body: some View {
        Circle()
            .fill(Color.primary)
            .frame(width: size, height: size)
            .overlay(
                Text(initials.uppercased())
                    .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                    .foregroundColor(.onPrimary)
            )
    }
}
