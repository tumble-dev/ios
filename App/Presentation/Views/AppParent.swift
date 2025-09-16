//
//  HomeView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/22.
//

import SwiftUI
import MijickPopupView

/// All navigation occurs from this view
struct AppParent: View {
    @ObservedObject var viewModel: ParentViewModel
    @ObservedObject var appController: AppController = .shared
    
    private let homeView: AnyView
    private let bookmarkView: AnyView
    private let accountView: AnyView
    private let searchView: AnyView
    
    private let navigationBarAppearance = UINavigationBar.appearance()
    
    init(viewModel: ParentViewModel) {
        navigationBarAppearance.titleTextAttributes = [.font: navigationBarFont()]
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "OnBackground")!]
        
        self.viewModel = viewModel
        self.homeView = Home(
            viewModel: viewModel.homeViewModel,
            parentViewModel: viewModel).eraseToAnyView()
        self.bookmarkView = Bookmarks(
            viewModel: viewModel.bookmarksViewModel,
            parentViewModel: viewModel).eraseToAnyView()
        self.accountView = Account(viewModel: viewModel.accountPageViewModel).eraseToAnyView()
        self.searchView = Search(viewModel: viewModel.searchViewModel).eraseToAnyView()
    }
    
    @ViewBuilder
    private func getView(for tab: TabbarTabType) -> some View {
        switch tab {
        case .home: homeView
        case .bookmarks: bookmarkView
        case .account: accountView
        case .search: searchView
        }
    }
    
    var body: some View {
        VStack (spacing: 0) {
            if #available(iOS 26.0, *) {
                TabView {
                    ForEach(TabbarTabType.allValues) { tab in
                        Tab("", systemImage: tab.rawValue) {
                            getView(for: tab)
                        }
                    }
                }
                .onChange(of: appController.selectedAppTab) { oldValue, newValue in
                    HapticsController.triggerHapticLight()
                }
            } else {
                ZStack {
                    homeView
                        .opacity(appController.selectedAppTab == .home ? 1 : 0)
                    bookmarkView
                        .opacity(appController.selectedAppTab == .bookmarks ? 1 : 0)
                    searchView
                        .opacity(appController.selectedAppTab == .search ? 1 : 0)
                    accountView
                        .opacity(appController.selectedAppTab == .account ? 1 : 0)
                }
                CustomTabBar(selectedTab: $appController.selectedAppTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $viewModel.userNotOnBoarded, content: {
            OnBoarding(finishOnBoarding: viewModel.finishOnboarding)
        })
        .navigationViewStyle(StackNavigationViewStyle())
        .onOpenURL(perform: { url in
            if PreferenceManager().openEventFromWidget {
                guard let event = RealmManager().getEventByEventId(eventId: url.absoluteString) else { return }
                AppController.shared.eventSheet = EventDetailsSheetModel(event: event)
            }
        })
    }
}
