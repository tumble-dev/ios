//
//  ResourceBookings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-14.
//

import SwiftUI

struct ResourceBookings: View {
    @ObservedObject var viewModel: ResourceViewModel
    let updateBookingNotifications: () -> Void
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.medium) {
                    ResourceDatePicker(date: $viewModel.selectedPickerDate)
                    Divider()
                        .foregroundColor(.onBackground)
                    switch viewModel.resourceBookingPageState {
                    case .loading:
                        VStack {
                            CustomProgressIndicator()
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 200,
                            maxHeight: .infinity,
                            alignment: .center
                        )
                    case .loaded:
                        ResourceLocationsList(
                            parentViewModel: viewModel,
                            selectedPickerDate: $viewModel.selectedPickerDate,
                            updateBookingNotifications: updateBookingNotifications
                        )
                    case .error:
                        VStack {
                            if isWeekend(on: viewModel.selectedPickerDate) {
                                Info(title: NSLocalizedString("No rooms available on weekends", comment: ""), image: "moon.zzz")
                            } else {
                                Info(title: NSLocalizedString("Could not contact the server, try again later", comment: ""), image: "arrow.clockwise")
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 200,
                            maxHeight: .infinity,
                            alignment: .center
                        )
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .background(Color.background)
        .onAppear {
            Task {
                await viewModel.getAllResourceData(date: viewModel.selectedPickerDate)
            }
        }
    }

}
