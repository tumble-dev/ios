//
//  ResourceTimeDropdown.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import SwiftUI

struct TimeslotDropdown: View {
    let resource: Response.KronoxResourceElement
    let timeslots: [Response.TimeSlot]
    
    @State var isSelecting: Bool = false
    @State var selectionTitle: String = ""
    @Binding var selectedIndex: Int

    var body: some View {
        VStack {
            HStack {
                Text(selectionTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onSurface)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onSurface)
                    .rotationEffect(isSelecting ? .degrees(180) : .zero)
            }
            .padding(.horizontal, Spacing.medium)
            if isSelecting {
                Divider()
                    .background(.white)
                    .padding(.horizontal)
                    .padding(.bottom, Spacing.small)

                VStack(spacing: Spacing.medium * 2) {
                    ForEach(Array(timeslots.enumerated()), id: \.offset) { index, timeslot in
                        if let timeslotId = timeslot.id,
                           resource.availabilities.timeslotHasAvailable(for: timeslotId),
                           let start = timeslot.from?.convertToHoursAndMinutes(),
                           let end = timeslot.to?.convertToHoursAndMinutes()
                        {
                            DropdownMenuItemView(
                                isSelecting: $isSelecting,
                                selectiontitle: $selectionTitle,
                                selectedIndex: $selectedIndex,
                                item: DropdownItem(id: timeslotId,
                                                   title: "\(start) - \(end)",
                                                   onSelect: {
                                                       selectedIndex = index
                                                   })
                            )
                        }
                    }
                }
                .padding(.vertical, Spacing.small)
            }
        }
        .onAppear {
            if let start = timeslots[selectedIndex].from?.convertToHoursAndMinutes(),
               let end = timeslots[selectedIndex].to?.convertToHoursAndMinutes()
            {
                selectionTitle = "\(start) - \(end)"
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .background(Color.surface)
        .cornerRadius(10)
        .padding(.horizontal, Spacing.medium)
        .padding(.bottom, Spacing.medium)
        .onTapGesture {
            withAnimation(.easeInOut) {
                isSelecting.toggle()
            }
        }
    }
}

private struct DropdownItem: Identifiable {
    let id: Int
    let title: String
    let onSelect: () -> Void
}

private struct DropdownMenuItemView: View {
    @Binding var isSelecting: Bool
    @Binding var selectiontitle: String
    @Binding var selectedIndex: Int

    let item: DropdownItem

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut) {
                isSelecting = false
                selectiontitle = item.title
            }
            item.onSelect()
        }) {
            HStack {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onSurface)
                Spacer()
                if selectedIndex == item.id {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.onSurface)
                }
            }
            .padding(.horizontal)
            .foregroundColor(.onBackground)
        }
    }
}
