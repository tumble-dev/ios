//
//  AccountScreen.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

struct AccountScreen: View {
    @ObservedObject var context: AccountScreenViewModel.Context
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch context.viewState.userState {
            case .loading:
                InfoView.loading("Loading account...")
            case .error(let msg):
                InfoView.error(title: "Could not load your account", subtitle: msg)
            case .missing:
                InfoView.empty(
                    title: "You have no connected accounts",
                    subtitle: "Connect one or more accounts from the settings screen",
                    icon: "person.crop.circle.fill.badge.xmark"
                )
            case .loaded(let user):
                AccountContentView(
                    user: user,
                    dataState: context.viewState.dataState,
                    onAction: { action in
                        context.send(viewAction: action)
                    }
                )
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    context.send(viewAction: .close)
                }
                .foregroundColor(.onSurface)
            }
        }
    }
}

struct AccountContentView: View {
    let user: TumbleUser
    let dataState: AccountScreenDataState
    let onAction: (AccountScreenViewAction) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // User Info Header
                UserInfoCard(user: user)
                    .padding(.top, 8)
                
                // Content based on data state
                switch dataState {
                case .loading:
                    LoadingDataView()
                case .loaded(let events, let bookings):
                    AccountDataView(
                        events: events,
                        bookings: bookings,
                        onAction: onAction
                    )
                case .empty:
                    EmptyDataView()
                case .error(let message):
                    ErrorDataView(message: message)
                case .hidden:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.background)
    }
}

struct UserInfoCard: View {
    let user: TumbleUser
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.primary.opacity(0.6), .yellow.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                
                Text(String(user.name.prefix(1)))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.onSurface)
            }
            
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.onSurface)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.onSurface)
                
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.caption)
                    Text(user.school.uppercased(with: .autoupdatingCurrent))
                        .font(.caption)
                        .foregroundColor(.onBackground)
                }
                .foregroundColor(.onSurface)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.background)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct AccountDataView: View {
    let events: [Response.UserEvent]
    let bookings: [Response.Booking]
    let onAction: (AccountScreenViewAction) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Active Bookings Section
            SectionCard(
                title: "Active Bookings",
                count: bookings.count,
                systemImage: "calendar.badge.clock",
                gradientColors: [.blue, .cyan],
                onTap: { onAction(.showResources) }
            ) {
                if bookings.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No Active Bookings",
                        subtitle: "Your resource bookings will appear here"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(bookings.prefix(3).enumerated()), id: \.offset) { _, booking in
                            BookingRowView(booking: booking)
                        }
                        
                        if bookings.count > 3 {
                            ShowMoreButton(
                                text: "View \(bookings.count - 3) more",
                                gradientColors: [.blue, .cyan],
                                action: { onAction(.showResources) }
                            )
                        }
                    }
                }
            }
            
            // Registered Events Section
            SectionCard(
                title: "Registered Events",
                count: events.count,
                systemImage: "calendar.badge.checkmark",
                gradientColors: [.green, .mint],
                onTap: { onAction(.showEvents) }
            ) {
                if events.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.checkmark",
                        title: "No Registered Events",
                        subtitle: "Your registered events will appear here"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, event in
                            EventRowView(event: event)
                        }
                        
                        if events.count > 3 {
                            ShowMoreButton(
                                text: "View \(events.count - 3) more",
                                gradientColors: [.green, .mint],
                                action: { onAction(.showEvents) }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let count: Int
    let systemImage: String
    let gradientColors: [Color]
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: systemImage)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if count > 0 {
                            Text("\(count) active")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Text("View All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Content
            content()
        }
        .padding(.spacingXL)
        .cardStyle()
    }
}

struct BookingRowView: View {
    let booking: Response.Booking
    
    var needsConfirmation: Bool {
        booking.showConfirmButton
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator with glow effect
            ZStack {
                Circle()
                    .fill(needsConfirmation ? Color.orange : Color.green)
                    .frame(width: 12, height: 12)
                
                if needsConfirmation {
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .blur(radius: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Resource \(booking.resourceId)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let timeSlot = booking.timeSlot {
                        Text(timeSlot.timeString())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text("Location: \(booking.locationId)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if needsConfirmation {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Confirmation required")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .cardStyle()
    }
}

struct EventRowView: View {
    let event: Response.UserEvent
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }
    
    private var isUpcoming: Bool {
        event.start > Date()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(isUpcoming ? Color.green : Color.gray.opacity(0.6))
                    .frame(width: 12, height: 12)
                
                if isUpcoming {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .blur(radius: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(event.type)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                HStack {
                    Text(dateFormatter.string(from: event.start))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if isUpcoming {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("Upcoming")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .cardStyle()
    }
}

struct ShowMoreButton: View {
    let text: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.3) },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.6) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gray.opacity(0.6))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }
}

struct LoadingDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<2, id: \.self) { _ in
                VStack(spacing: 20) {
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 140, height: 20)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(0..<2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 72)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct EmptyDataView: View {
    var body: some View {
        EmptyStateView(
            icon: "tray",
            title: "No Data Available",
            subtitle: "Your bookings and events will appear here when available"
        )
        .padding(.vertical, 40)
    }
}

struct ErrorDataView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Error Loading Data")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.onBackground)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.onBackground)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}
