//
//  EventDetailsView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-31.
//

import SwiftUI

struct EventDetailsSheet: View {
    @ObservedObject var viewModel: EventDetailsSheetViewModel
    @State var presentColorPicker: Bool = false
        
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.medium) {
                    EventDetailsCard(
                        parentViewModel: viewModel,
                        openColorPicker: openColorPicker,
                        event: viewModel.event,
                        color: viewModel.color
                    )
                    EventDetailsBody(event: viewModel.event)
                    Spacer()
                }
            }
            .background(Color.background)
            .background(
                ColorPicker(
                    NSLocalizedString("Select course color", comment: ""),
                    selection: $viewModel.color, supportsOpacity: false)
                .labelsHidden().opacity(0)
            )
            .onDisappear(perform: onClose)
        }
        .padding(.top, Spacing.header)
        .background(Color.background)
        .overlay(
            CloseCoverButton(onClick: onClose),
            alignment: .topTrailing
        )
        .overlay(
            Text(NSLocalizedString("Details", comment: ""))
                .sheetTitle()
            ,alignment: .top
        )
    }
    
    func onClose() {
        viewModel.updateCourseColor()
        AppController.shared.eventSheet = nil
    }
    
    func openColorPicker() {
        UIColorWellHelper.helper.execute?()
    }
}
