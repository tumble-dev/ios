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
        VStack {}
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background()
            .ignoresSafeArea(edges: .top)
            .ignoresSafeArea(.keyboard)
    }
}
