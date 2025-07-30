//
//  SideBarToggleButtonView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-01.
//

import SwiftUI

struct SettingsButton: View {
    @StateObject var viewModel: SettingsViewModel = ViewModelFactory.shared.makeViewModelSettings()
    
    var body: some View {
        NavigationLink(destination:
            Settings(
                viewModel: viewModel
            ),
            label: {
                Image(systemName: "gearshape")
                    .actionIcon()
            })
    }
}
