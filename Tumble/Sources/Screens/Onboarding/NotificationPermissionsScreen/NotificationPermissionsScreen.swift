//
//  NotificationPermissionsScreen.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

/// A prompt that asks the user whether they would like to enable Notifications or not.
struct NotificationPermissionsScreen: View {
    @ObservedObject var context: NotificationPermissionsScreenViewModel.Context
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with proper spacing
            VStack(spacing: 40) {
                Spacer()
                
                heroSection
                
                benefitsSection
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Bottom action area
            bottomActionArea
        }
        .background(Color.background.ignoresSafeArea(.all))
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                isAnimated = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 28) {
            // Animated notification icon
            notificationIcon
                .scaleEffect(isAnimated ? 1.0 : 0.8)
            
            // Main title and subtitle
            VStack(spacing: 16) {
                Text("Stay in the Loop")
                    .font(.system(.largeTitle))
                    .bold()
                    .foregroundColor(.onBackground)
                    .multilineTextAlignment(.center)
                
                Text("Get notified about important updates, deadlines, and events so you never miss what matters most.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.onBackground)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var notificationIcon: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.primary.opacity(0.3),
                            Color.primary.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 40,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1 : 0)
            
            // Main circle background
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primary, Color.primary.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color.primary.opacity(0.4), radius: 20, x: 0, y: 10)
            
            Image(systemName: "bell.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.onPrimary)
                .rotationEffect(.degrees(isAnimated ? 15 : -15))
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(0.8),
                    value: isAnimated
                )
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(spacing: 24) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefit in
                benefitRow(
                    icon: benefit.icon,
                    title: benefit.title,
                    description: benefit.description
                )
            }
        }
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline))
                    .foregroundColor(.onBackground)
                
                Text(description)
                    .font(.system(.subheadline))
                    .foregroundColor(.onBackground.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Action Area
    
    private var bottomActionArea: some View {
        VStack(spacing: 20) {
            // Primary action button
            Button(action: { context.send(viewAction: .enable) }) {
                HStack(spacing: 8) {
                    if context.viewState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                        
                        Text("Setting up...")
                            .font(.system(.headline))
                    } else {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Enable Notifications")
                            .font(.system(.headline))
                    }
                }
                .foregroundColor(.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: .radiusL))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(context.viewState.isProcessing)
            
            // Secondary action button - only show if not processing
            if !context.viewState.isProcessing {
                Button(action: { context.send(viewAction: .notNow) }) {
                    Text("Maybe Later")
                        .font(.system(.body))
                        .foregroundColor(.onBackground.opacity(0.7))
                        .frame(height: 48)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            // Privacy note
            Text("You can change this in Settings at any time")
                .font(.system(.caption))
                .foregroundColor(.onBackground.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Data
    
    private let benefits = [
        (
            icon: "calendar.badge.clock",
            title: "Never Miss Deadlines",
            description: "Get timely reminders for assignments and important dates"
        ),
        (
            icon: "megaphone.fill",
            title: "Important Announcements",
            description: "Stay updated with critical information and updates"
        ),
        (
            icon: "person.2.fill",
            title: "Event Reminders",
            description: "Get notified about upcoming events and activities"
        )
    ]
}
