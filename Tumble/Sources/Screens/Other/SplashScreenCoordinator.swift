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
        ZStack {
            Color.background
                .ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                
                // App logo in center
                Image("AppIconOpaque")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                Spacer()
                
                // Simple text at bottom
                Text("Tumble")
                    .font(.titleLarge)
                    .foregroundColor(.primary)
                    .padding(.bottom, .spacingL)
            }
        }
    }
}

#Preview {
    SplashScreen()
}
