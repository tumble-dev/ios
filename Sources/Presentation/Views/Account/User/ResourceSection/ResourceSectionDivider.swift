//
//  UserOptions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-13.
//

import SwiftUI

enum ResourceType {
    case event
    case resource
}

struct ResourceSectionDivider<Content: View>: View {
    let content: Content
    let title: String
    let resourceType: ResourceType?
    let onBook: (() -> Void)?
    let destination: AnyView?
    
    init(
        title: String,
        resourceType: ResourceType? = nil,
        destination: AnyView? = nil,
        onBook: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.resourceType = resourceType
        self.onBook = onBook
        self.destination = destination
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onBackground)
                Spacer()
                if let destination = destination {
                    NavigationLink(destination: destination, label: {
                        HStack {
                            switch resourceType! {
                            case .event:
                                ResourceNavigationItem(title: "See all")
                            case .resource:
                                ResourceNavigationItem(title: "Book more")
                            }
                        }
                    })
                }
            }
            .padding(.bottom, Spacing.small)
            content
        }
        .padding(.vertical, Spacing.medium / 2)
        .padding(.horizontal, Spacing.medium)
    }
}


private struct ResourceNavigationItem: View {
    
    let title: String
    
    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.onPrimary)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.onPrimary)
        }
        .padding(10)
        .background(Color.primary)
        .cornerRadius(15)
    }
    
}
