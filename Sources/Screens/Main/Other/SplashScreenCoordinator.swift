//
//  SplashScreenCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

class SplashScreenCoordinator: CoordinatorProtocol {
    func toPresentable() -> AnyView {
        AnyView(SplashScreen())
    }
}

struct SplashScreen: View {
    var body: some View {
        Image("AppIconOpaque")
    }
}
