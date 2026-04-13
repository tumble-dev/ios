//
//  AnalyticsPermissionsScreen.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-25.
//

import Combine
import SwiftUI

struct AnalyticsPermissionsScreen: View {
    @ObservedObject var context: AnalyticsPermissionsScreenViewModel.Context
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
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
        .background(Color.tumbleBackground.ignoresSafeArea(.all))
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
            // Animated analytics icon
            analyticsIcon
                .scaleEffect(isAnimated ? 1.0 : 0.8)
            
            // Main title and subtitle
            VStack(spacing: 16) {
                Text("Help Us Improve")
                    .font(.system(.largeTitle))
                    .foregroundColor(.tumbleOnBackground)
                    .multilineTextAlignment(.center)
                
                Text("Share anonymous usage data to help us build better features and fix issues faster.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.tumbleOnBackground)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var analyticsIcon: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.tumblePrimary.opacity(0.3),
                            Color.tumblePrimary.opacity(0.1),
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
                        gradient: Gradient(colors: [Color.tumblePrimary, Color.tumblePrimary.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color.tumblePrimary.opacity(0.4), radius: 20, x: 0, y: 10)
            
            // Chart icon with subtle animation
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.tumbleOnPrimary)
                .scaleEffect(isAnimated ? 1.0 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(1.0),
                    value: isAnimated
                )
            
            // Animated data points
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.tumbleOnPrimary.opacity(0.8))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat([15, -10, 20][index]),
                        y: CGFloat([-15, 10, -25][index])
                    )
                    .scaleEffect(isAnimated ? 1.0 : 0.0)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .delay(Double(index) * 0.2 + 1.2),
                        value: isAnimated
                    )
            }
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
                    .fill(Color.tumblePrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.tumblePrimary)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline))
                    .foregroundColor(.tumbleOnBackground)
                
                Text(description)
                    .font(.system(.subheadline))
                    .foregroundColor(.tumbleOnBackground.opacity(0.8))
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
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Help Improve Tumble")
                        .font(.system(.headline))
                }
                .foregroundColor(.tumbleOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.tumblePrimary)
                .clipShape(RoundedRectangle(cornerRadius: .radiusL))
            }
            .buttonStyle(PrimaryButtonStyle())
            
            // Secondary action button
            Button(action: { context.send(viewAction: .notNow) }) {
                Text("No Thanks")
                    .font(.system(.body))
                    .foregroundColor(.tumbleOnBackground.opacity(0.7))
                    .frame(height: 48)
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // Privacy note
            VStack(spacing: 8) {
                Text("All data is anonymous and secure")
                    .font(.system(.caption))
                    .foregroundColor(.tumbleOnBackground.opacity(0.8))
                
                Text("You can change this in Settings at any time")
                    .font(.system(.caption))
                    .foregroundColor(.tumbleOnBackground.opacity(0.6))
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Data
    
    private let benefits = [
        (
            icon: "wrench.and.screwdriver.fill",
            title: "Better Bug Fixes",
            description: "Help us identify and fix issues you encounter"
        ),
        (
            icon: "sparkles",
            title: "Improved Features",
            description: "Guide development of features you actually use"
        ),
        (
            icon: "gauge.high",
            title: "Enhanced Performance",
            description: "Optimize the app based on real usage patterns"
        )
    ]
}
