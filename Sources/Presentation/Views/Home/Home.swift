//
//  HomePageView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/22.
//

import RealmSwift
import SwiftUI

struct Home: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var parentViewModel: ParentViewModel
    @ObservedResults(Schedule.self, configuration: realmConfig) var schedules
    
    @ObservedObject var appController: AppController = .shared
    @State private var showSheet: Bool = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ScrollView(.vertical) {
                    if viewModel.newsSectionStatus == .loaded {
                        News(news: viewModel.news?.pick(length: 4), showOverlay: $showSheet)
                            .padding(.horizontal, Spacing.medium)
                            .padding(.top, Spacing.small)
                    }
                    Spacer()
                    VStack {
                        switch viewModel.status {
                        case .available:
                            HomeAvailable(
                                eventsForToday: $viewModel.todaysEventsCards,
                                nextClass: viewModel.nextClass,
                                swipedCards: $viewModel.swipedCards
                            )
                        case .loading:
                            VStack {
                                CustomProgressIndicator()
                            }
                            .frame(width: geo.size.width)
                            .frame(minHeight: geo.size.height)
                        case .noBookmarks:
                            HomeNoBookmarks()
                        case .notAvailable:
                            HomeNotAvailable()
                        case .error:
                            Info(title: NSLocalizedString("Something went wrong", comment: ""), image: nil)
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.background)
                .fullScreenCover(
                    isPresented: $showSheet,
                    content: {
                        NewsSheet(news: viewModel.news, showSheet: $showSheet)
                })
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(NSLocalizedString("Home", comment: ""))
        }
        .tag(TabbarTabType.home)
    }
}
