//
//  SchedulePreviewView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/18/22.
//

import RealmSwift
import SwiftUI
import WidgetKit

struct SearchPreviewSheet: View {
    @ObservedObject var viewModel: SearchPreviewViewModel
    @ObservedResults(Schedule.self, configuration: realmConfig) var schedules
    
    let programmeId: String
    let schoolId: String
    let scheduleTitle: String
    let closePreview: () -> Void
    
    var body: some View {
        VStack {
            switch viewModel.status {
            case .loaded:
                SearchPreviewList(
                    viewModel: viewModel
                )
                .padding(.top, Spacing.header)
            case .loading:
                CustomProgressIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .error:
                if let failure = viewModel.errorMessage {
                    Info(title: failure, image: nil)
                } else {
                    Info(title: NSLocalizedString("Something went wrong", comment: ""), image: nil)
                }
            case .empty:
                Info(title: NSLocalizedString("Schedule seems to be empty", comment: ""), image: nil)
            }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        )
        .background(Color.background)
        .overlay(
            CloseCoverButton(onClick: closePreview),
            alignment: .topTrailing
        )
        .if(viewModel.status == .loaded, transform: { view in
            view.overlay(
                BookmarkButton(
                    bookmark: bookmark,
                    buttonState: $viewModel.buttonState
                )
                ,alignment: .topLeading
            )
        })
        .onAppear {
            viewModel.getSchedule(
                programmeId: programmeId,
                schoolId: schoolId,
                schedules: Array(schedules)
            )
        }
    }
    
    func bookmark() {
        viewModel.bookmark(
            scheduleId: programmeId,
            schedules: Array(schedules),
            schoolId: schoolId,
            scheduleTitle: scheduleTitle
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}
