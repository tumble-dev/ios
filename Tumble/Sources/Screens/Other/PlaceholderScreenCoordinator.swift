//
//  PlaceholderScreenCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import SwiftUI

class PlaceholderScreenCoordinator: CoordinatorProtocol {
    private let showBackgroundGradient: Bool
    
    init(showBackgroundGradient: Bool = false) {
        self.showBackgroundGradient = showBackgroundGradient
    }
    
    func toPresentable() -> AnyView {
        AnyView(PlaceHolderScreen(showBackgroundGradient: showBackgroundGradient))
    }
}

struct PlaceHolderScreen: View {
    let showBackgroundGradient: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(Color.tumbleOnBackground)
            
            VStack(spacing: 8) {
                Text("Select an event")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose an event from your bookmarks to view details")
                    .font(.subheadline)
                    .foregroundStyle(Color.tumbleOnBackground)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tumbleBackground)
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(.keyboard)
    }
}
