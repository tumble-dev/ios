//
//  RoomContainerCar.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/23/23.
//

import SwiftUI

struct TimeslotCard: View {
    let onBook: () -> Void
    let locationId: String
    @Binding var bookingButtonState: BookingButtonState
    
    var body: some View {
        HStack {
            Text(locationId)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.onSurface)
            Spacer()
            Button(action: {
                if bookingButtonState != .booked {
                    onBook()
                }
            }, label: {
                switch bookingButtonState {
                case .loading:
                    CustomProgressIndicator(color: .onPrimary)
                        .padding()
                case .booked:
                    Text(NSLocalizedString("Booked", comment: ""))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.onPrimary)
                        .padding(Spacing.medium / 2)
                case .available:
                    Text(NSLocalizedString("Book", comment: ""))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.onPrimary)
                        .padding(Spacing.medium / 2)
                }
            })
            .disabled(bookingButtonState == .booked)
            .buttonStyle(BookButtonStyle())
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, maxHeight: 70)
        .background(Color.surface)
        .cornerRadius(10)
    }
}
