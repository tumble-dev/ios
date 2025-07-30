//
//  SchedulePreviewGrouperListView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2022-12-02.
//

import Combine
import SwiftUI

enum ButtonState {
    case loading
    case saved
    case notSaved
    case disabled
}

struct SearchPreviewList: View {
    @ObservedObject var viewModel: SearchPreviewViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.small) {
                ForEach(createDays() ?? [], id: \.id) { day in
                    if !day.events.isEmpty {
                        VStack {
                            DayResponseHeader(day: day)
                            VStack(spacing: Spacing.medium) {
                                ForEach(day.events, id: \.id) { event in
                                    VerboseEventResponseButtonLabel(
                                        event: event,
                                        color: viewModel.courseColorsForPreview[event.course.id]?.toColor() ?? .white
                                    )
                                }
                            }
                        }
                        .padding(.vertical, Spacing.large)
                    }
                }
            }
        }
        .cornerRadius(15)
        .padding(.horizontal, Spacing.medium)
        .ignoresSafeArea()
    }
    
    func createDays() -> [Response.Day]? {
        return viewModel.schedule?.flatten().ordered()
    }
}
