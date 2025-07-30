//
//  SchedulePageMainView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/21/22.
//

import RealmSwift
import SwiftUI

struct Bookmarks: View {
    @ObservedObject var viewModel: BookmarksViewModel
    @ObservedObject var parentViewModel: ParentViewModel
    @ObservedObject var appController: AppController = .shared
    
    @State var viewType: ViewType
    
    @Namespace private var animationNamespace
    
    init(viewModel: BookmarksViewModel, parentViewModel: ParentViewModel) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel
        self.viewType = viewModel.defaultViewType
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                switch viewModel.status {
                case .loading:
                    CustomProgressIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                case .loaded:
                    ScrollViewReader { proxy in
                        ZStack (alignment: .bottom) {
                            TabView (selection: $viewType) {
                                BookmarkListView(
                                    days: viewModel.bookmarkData.days,
                                    appController: appController,
                                    viewModel: viewModel
                                )
                                .tag(ViewType.list)
                                
                                BookmarkCalendarView(
                                    appController: appController,
                                    calendarEventsByDate: viewModel.bookmarkData.calendarEventsByDate,
                                    days: viewModel.bookmarkData.days
                                )
                                .tag(ViewType.calendar)
                                
                                BookmarkWeekView(
                                    scheduleWeeks: viewModel.bookmarkData.weeks,
                                    viewModel: viewModel
                                )
                                .tag(ViewType.week)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .onChange(of: viewType) { newValue in
                                withAnimation {
                                    viewModel.setViewType(viewType: newValue)
                                }
                            }
                            .onChange(of: viewModel.defaultViewType) { newValue in
                                withAnimation {
                                    viewType = newValue
                                }
                            }
                            .ignoresSafeArea(edges: .bottom)
                            
                            HStack(alignment: .center, spacing: 12.5) {
                                ViewSwitcher(parentViewModel: viewModel)
                                    .offset(y: viewModel.viewSwitcherVisible ? 0 : 100)
                                    .scaleEffect(viewModel.viewSwitcherVisible ? 1 : 0.8, anchor: .bottom)
                                    .opacity(viewModel.viewSwitcherVisible ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.4), value: viewModel.viewSwitcherVisible)
                                    .transition(AnyTransition.move(edge: .leading).combined(with: .opacity))

                                if viewModel.toTopButtonVisible {
                                    ToTopButton(proxy: proxy)
                                        .offset(x: 0, y: viewModel.toTopButtonVisible ? 0 : 200)
                                        .scaleEffect(viewModel.toTopButtonVisible ? 1 : 0.8, anchor: .trailing)
                                        .opacity(viewModel.toTopButtonVisible ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.4), value: viewModel.toTopButtonVisible)
                                        .transition(AnyTransition.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            .padding(.bottom, Spacing.medium)

                        }
                    }
                case .uninitialized:
                    Info(title: NSLocalizedString("No bookmarks yet", comment: ""), image: "bookmark.slash")
                case .hiddenAll:
                    Info(title: NSLocalizedString("All your bookmarks are hidden", comment: ""), image: "bookmark.slash")
                case .error:
                    Info(title: NSLocalizedString("Something went wrong", comment: ""), image: nil)
                case .empty:
                    Info(title: NSLocalizedString("Your visible schedules do not contain any events", comment: ""), image: "calendar.badge.exclamationmark")
                }
            }
            .background(Color.background)
            .onAppear {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            .fullScreenCover(item: $appController.eventSheet) { (eventSheet: EventDetailsSheetModel) in
                EventDetailsSheet(
                    viewModel: viewModel.createViewModelEventSheet(
                        event: eventSheet.event))
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(NSLocalizedString("Bookmarks", comment: ""))
        }
        .tag(TabbarTabType.bookmarks)
    }
}
