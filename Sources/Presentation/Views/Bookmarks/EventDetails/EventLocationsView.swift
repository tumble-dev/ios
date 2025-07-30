//
//  EventLocationsView.swift
//  App
//
//  Created by Timur Ramazanov on 26.09.2024.
//

import SwiftUI
import RealmSwift

struct EventLocationsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EventLocationsViewModel
    
    init(event: Event) {
        self.viewModel = .init(event: event)
    }
    
    func close() -> Void {
        dismiss()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack {
                    switch viewModel.status {
                    case .loading:
                        Info(title: NSLocalizedString("Looking for the event's school", comment: ""), image: "binoculars")
                            .padding(.top, 100)
                    case .notFound:
                        Info(title: NSLocalizedString("Could not find the event's location", comment: ""), image: "mappin.slash")
                            .padding(.top, 100)
                    case .notAvailable:
                        Info(title: NSLocalizedString("The map for this campus is not available yet", comment: ""), image: "map")
                            .padding(.top, 100)
                    case .available:
                        CampusMapView(
                            selectedLocations: viewModel.selectedLocations,
                            schoolDomain: viewModel.school!.domain,
                            schoolColor: viewModel.school!.color
                        )
                        .frame(minHeight: UIScreen.main.bounds.width * 1.33)
                        .padding(.top, Spacing.large)
                    }
                }
            }
            
            SectionDivider(title: NSLocalizedString("Locations", comment: ""), image: "mappin.and.ellipse") {
                ForEach(viewModel.event.locations, id: \._id) { location in
                    Text(location.locationId)
                }
            }
        }
        
        .padding(.top, Spacing.header)
        .background(Color.background)
        .overlay(
            CloseCoverButton(onClick: close),
            alignment: .topTrailing
        )
        .overlay(
            Text(NSLocalizedString(viewModel.school?.name ?? "", comment: ""))
                .sheetTitle(),
            alignment: .top
        )
    }
}
