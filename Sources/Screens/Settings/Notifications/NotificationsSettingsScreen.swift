//
//  NotificationsSettingsScreen.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import SwiftUI
import Combine

struct NotificationsSettingsScreen: View {
    
    @ObservedObject var context: NotificationsSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
