//
//  HomeView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/16/22.
//

import SwiftUI

struct Root: View {
    
    @AppStorage(SharedPreferenceKey.appearance.rawValue) private var appearance = AppearanceType.system.rawValue
    let viewModel: ParentViewModel = ViewModelFactory.shared.makeViewModelParent()
    
    var body: some View {
        ZStack {
            AppParent(viewModel: viewModel)
        }
        .edgesIgnoringSafeArea(.all)
        .ignoresSafeArea(.keyboard)
        .onChange(of: appearance) { newValue in
            changeTheme(to: newValue)
        }
        .onAppear {
            changeTheme(to: appearance)
        }
    }
    
    func changeTheme(to theme: String) {
        let style = getThemeColorScheme(appearance: theme)
        
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}
