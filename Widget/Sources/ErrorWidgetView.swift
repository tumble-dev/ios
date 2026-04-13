//
//  ErrorWidgetView.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import SwiftUI
import WidgetKit

struct ErrorWidgetView: View {
    let message: String
    @Environment(\.widgetFamily) private var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            mediumWidgetView
        }
    }
    
    private var smallWidgetView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.red)
            
            Text("Error")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.tumblePrimary)
            
            Text("Unable to load events")
                .font(.caption2)
                .foregroundColor(.tumbleSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
    }
    
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unable to Load Events")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tumblePrimary)
                
                Text("There was an error loading your events. Please try opening the Tumble app to refresh your data.")
                    .font(.caption)
                    .foregroundColor(.tumbleSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
    }
}
