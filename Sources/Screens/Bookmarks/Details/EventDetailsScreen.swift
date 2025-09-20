//
//  EventDetailScreen.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

struct EventDetailsScreen: View {
    
    @ObservedObject var context: EventDetailsScreenViewModel.Context
    @State private var showColorPicker = false
    @State private var selectedColor = Color.gray
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch context.viewState.dataState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .loaded(let event):
                    EventInfo(
                        event: event,
                        courseColor: selectedColor,
                        showColorPicker: $showColorPicker,
                        selectedColor: $selectedColor,
                        onColorSelected: { color in
                            selectedColor = color
                            showColorPicker = false
                        }
                    )
                    
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
        ToolbarItem(placement: .primaryAction) {
            Button("Done") {
                context.send(viewAction: .close)
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                context.send(viewAction: .showColorPicker)
            } label: {
                Image(systemName: "paintpalette")
            }
            .accessibilityLabel("Change Color")
        }
    }
}

struct EventInfo: View {
    let event: Response.Event
    let courseColor: Color
    @Binding var showColorPicker: Bool
    @Binding var selectedColor: Color
    let onColorSelected: (Color) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            EventHeaderCard(
                event: event,
                eventColor: courseColor
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
                if !event.teachers.isEmpty {
                    DetailCard(
                        icon: "person.fill",
                        title: event.teachers.count == 1 ? "Teacher" : "Teachers"
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(event.teachers, id: \.id) { teacher in
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
}

struct EventHeaderCard: View {
    let event: Response.Event
    let eventColor: Color
    
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
                            .fill(eventColor)
                            .frame(width: 8, height: 8)
                        
                        Text(event.courseName)
                            .font(.subheadline)
                            .foregroundColor(.onSurface.opacity(0.8))
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}
