//
//  ResourceScreen.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-10-30.
//

import SwiftUI

struct ResourceSelectionScreen: View {
    @ObservedObject var context: ResourceSelectionScreenViewModel.Context
    @State private var selectedPickerDate: Date = .init()
    
    var body: some View {
        VStack(spacing: 0) {
            ResourceDatePicker(
                selectedDate: $selectedPickerDate,
                onDateChange: { date in
                    context.send(viewAction: .loadResources(date))
                }
            )
            
            Divider()
            
            switch context.viewState.dataState {
            case .loading:
                Spacer()
                ProgressView()
                Spacer()
                
            case .error:
                VStack {
                    Spacer()
                    InfoView.error(
                        title: "No resources available",
                        subtitle: "No resources available for this date. You may be attempting to access them on a weekend."
                    )
                    Spacer()
                }
                .padding(10)
                
            case .loaded(let resources):
                ResourceLocationsList(
                    resources: resources,
                    selectedPickerDate: selectedPickerDate,
                    onSelectResource: { resource in
                        context.send(viewAction: .selectResource(resource, selectedPickerDate))
                    }
                )
                
            case .empty:
                Spacer()
                InfoView.empty(title: "No available resources")
                Spacer()
                
            case .hidden:
                EmptyView()
            }
        }
        .background(Color.tumbleBackground)
        .navigationTitle("Select a Resource")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            context.send(viewAction: .loadResources(selectedPickerDate))
        }
    }
}

private struct ResourceDatePicker: View {
    @Binding var selectedDate: Date
    let onDateChange: (Date) -> Void
    
    var body: some View {
        DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .onChange(of: selectedDate) { newDate in
            onDateChange(newDate)
        }
        .padding()
    }
}

private struct ResourceLocationsList: View {
    let resources: [Response.Resource]
    let selectedPickerDate: Date
    let onSelectResource: (Response.Resource) -> Void
    
    private var availableResources: [Response.Resource] {
        resources.filter { resource in
            calcAvailability(resource.availabilities ?? [:]) > 0
        }
    }
    
    var body: some View {
        if availableResources.isEmpty {
            VStack {
                Spacer()
                InfoView.empty(title: "No available resources")
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(availableResources, id: \.id) { resource in
                        let availableCounts = calcAvailability(resource.availabilities ?? [:])
                        
                        ResourceLocationItem(
                            resource: resource,
                            selectedPickerDate: selectedPickerDate,
                            availableCounts: availableCounts,
                            onClick: {
                                onSelectResource(resource)
                            }
                        )
                    }
                    
                    Spacer()
                        .frame(height: 60)
                }
                .padding(15)
            }
        }
    }
}

private struct ResourceLocationItem: View {
    let resource: Response.Resource
    let selectedPickerDate: Date
    let availableCounts: Int
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(uiColor: .label))
                        .lineLimit(1)
                    
                    DetailItemView(
                        icon: "calendar",
                        text: isoVerboseDateFormatter.string(from: selectedPickerDate)
                    )
                    
                    DetailItemView(
                        icon: "clock",
                        text: "Available timeslots: \(availableCounts)"
                    )
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.tumblePrimary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.tumblePrimary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct DetailItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}

private func calcAvailability(_ availabilities: [String: [Int: Response.AvailabilitySlot]]) -> Int {
    return availabilities.values.map { timeslots in
        timeslots.values.filter { $0.availability == .available }.count
    }.reduce(0, +)
}

private let isoVerboseDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
}()
