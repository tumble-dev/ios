//
//  EventDetailsScreen.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

struct EventDetailsScreen: View {
    @ObservedObject var context: EventDetailsScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch context.viewState.dataState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let event):
                    EventInfo(event: event)
                        .environmentObject(context)
                case .error(let message):
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(message)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(20)
        }
        .onAppear {
            context.send(viewAction: .loadEvent)
        }
        .toolbar { toolbar }
        .background(Color.background)
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {} label: {
                ColorPicker("Color", selection: context.colorPickerSelection)
            }
            .accessibilityLabel("Course Color")
        }
    }
}

struct EventInfo: View {
    let event: Response.Event
    @EnvironmentObject private var context: EventDetailsScreenViewModel.Context
    
    var body: some View {
        VStack(spacing: 16) {
            EventHeaderCard(
                event: event
            )
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Event Details")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.onBackground)
                    Spacer()
                }
                .padding(.top, 8)
                
                // Course
                DetailCard(
                    icon: "graduationcap.fill",
                    title: "Course"
                ) {
                    Text(event.courseName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.onSurface)
                }
                
                // Teachers
                if hasValidTeachers(event.teachers) {
                    DetailCard(
                        icon: "person.fill",
                        title: validTeachers(event.teachers).count == 1 ? "Teacher" : "Teachers"
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(validTeachers(event.teachers), id: \.id) { teacher in
                                Text("\(teacher.firstName) \(teacher.lastName)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.onSurface)
                            }
                        }
                    }
                }
                
                // Date
                DetailCard(
                    icon: "calendar",
                    title: "Date"
                ) {
                    Text(formatDateOnly(event.from))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.onSurface)
                }
                
                // Time
                DetailCard(
                    icon: "clock",
                    title: "Time"
                ) {
                    HStack(spacing: 0) {
                        Text(formatTimeOnly(event.from))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.onSurface)
                        
                        Text(" - ")
                            .font(.body)
                            .foregroundColor(.onSurface)
                        
                        Text(formatTimeOnly(event.to))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.onSurface)
                    }
                }
                
                // Locations
                if !event.locations.isEmpty {
                    DetailCard(
                        icon: "location.fill",
                        title: event.locations.count == 1 ? "Location" : "Locations"
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(event.locations, id: \.id) { location in
                                Text(location.id)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.onSurface)
                                
                                Text("Capacity: \(location.maxSeats) seats")
                                    .font(.caption)
                                    .foregroundColor(.onSurface)
                            }
                        }
                    }
                }
                
                // Special event indicator
                if event.isSpecial {
                    DetailCard(
                        icon: "star.fill",
                        title: "Special Event"
                    ) {
                        Text("This event looks like it could be an exam or other important occasion! Make sure to double-check.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                }
                
                // Notification Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Notification Settings")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.onBackground)
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    NotificationSettingsCard(event: event)
                }
            }
        }
    }
    
    private func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func hasValidTeachers(_ teachers: [Response.Teacher]) -> Bool {
        return !validTeachers(teachers).isEmpty
    }
    
    private func validTeachers(_ teachers: [Response.Teacher]) -> [Response.Teacher] {
        return teachers.filter { teacher in
            let fullName = [teacher.firstName, teacher.lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
}

struct EventHeaderCard: View {
    let event: Response.Event
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.onSurface)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(event.color)
                            .frame(width: 8, height: 8)
                        
                        Text(event.courseName)
                            .font(.subheadline)
                            .foregroundColor(.onSurface.opacity(0.8))
                    }
                }
                Spacer()
            }
        }
        .padding(.spacingL)
        .cardStyle()
    }
}

struct DetailCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                    .textCase(.uppercase)
                
                content
            }
            
            Spacer()
        }
        .padding(.spacingM)
        .cardStyle()
    }
}

struct NotificationSettingsCard: View {
    let event: Response.Event
    
    var body: some View {
        VStack(spacing: 12) {
            // Event-specific notification
            NotificationToggleRow(
                icon: "bell.fill",
                title: "Remind me about this event",
                subtitle: "Get notified 15 minutes before this event starts",
                isEnabled: context.viewState.isEventNotificationEnabled
            ) { enabled in
                context.send(viewAction: .toggleEventNotification(enabled))
            }
            
            Divider()
                .padding(.horizontal, -16)
            
            // Course-specific notification
            NotificationToggleRow(
                icon: "graduationcap.fill",
                title: "Notify me about all \(event.courseName) events",
                subtitle: "Get push notifications for all events in this course",
                isEnabled: context.viewState.isCourseNotificationEnabled
            ) { enabled in
                context.send(viewAction: .toggleCourseNotification(enabled))
            }
        }
        .padding(.spacingM)
        .cardStyle()
    }
    
    @EnvironmentObject private var context: EventDetailsScreenViewModel.Context
}

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.blue.opacity(0.2) : Color.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled ? .blue : .primary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.onSurface.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: onToggle
            ))
            .labelsHidden()
            .tint(.primary)
        }
    }
}
