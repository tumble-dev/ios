//
//  HomeViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/22.
//

import Combine
import Foundation
import RealmSwift
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Inject var kronoxManager: KronoxManager
    @Inject var realmManager: RealmManager
    
    @Published var newsSectionStatus: GenericPageStatus = .loading
    @Published var news: Response.NewsItems? = nil
    @Published var swipedCards: Int = 0
    @Published var status: HomeStatus = .loading
    @Published var todaysEventsCards: [WeekEventCardModel] = .init()
    @Published var nextClass: Event? = nil
    
    private var initialisedSession: Bool = false
    private let viewModelFactory: ViewModelFactory = .shared
    private let appController: AppController = .shared
    private let networkController: NetworkController = .shared
    private var schedulesToken: NotificationToken?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPublishers()
    }
    
    private func setupPublishers() {
        let networkConnectionPublisher = networkController.$connected.receive(on: RunLoop.main)
        let isUpdatingBookmarksPublisher = appController.$isUpdatingBookmarks.receive(on: RunLoop.main)
        Publishers.CombineLatest(networkConnectionPublisher, isUpdatingBookmarksPublisher)
            .sink { [weak self] connected, isUpdating in
                guard let self else { return }
                if connected && !self.initialisedSession && !isUpdating {
                    Task.detached(priority: .userInitiated) {
                        await self.fetchNews()
                    }
                }
                self.setupRealmListener()
            }
            .store(in: &cancellables)
    }
    
    /// Initializes a listener that performs updates on the
    /// visible cards and next upcoming event in the `Home` view
    private func setupRealmListener() {
        let schedules = realmManager.getAllLiveSchedules()
        schedulesToken = schedules.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(let results), .update(let results, _, _, _):
                self.createCarouselCards(schedules: Array(results))
                self.findNextUpcomingEvent(schedules: Array(results))
            case .error:
                self.status = .error
            }
        }
    }
    
    /// Attempts to retrieve news items published by
    /// our team, i.e. server updates, general updates, etc.
    private func fetchNews() async {
        DispatchQueue.main.async { [weak self] in
            self?.newsSectionStatus = .loading
        }
        do {
            let news: Response.NewsItems = try await kronoxManager.get(.news)
            DispatchQueue.main.async { [weak self] in
                self?.news = news
                self?.newsSectionStatus = .loaded
            }
        } catch {
            AppLogger.shared.error("Failed to retrieve news items: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.newsSectionStatus = .error
            }
        }
    }
    
    /// Finds the next upcoming event in all schedules
    private func findNextUpcomingEvent(schedules: [Schedule]) {
        if schedules.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.status = .noBookmarks
            }
            return
        }
        else if schedules.filter({ $0.toggled }).isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.status = .notAvailable
            }
            return
        }
        let nextUpcomingEvent = schedules.findNextUpcomingEvent()
        
        DispatchQueue.main.async { [weak self] in
            self?.nextClass = nextUpcomingEvent
            self?.status = .available
        }
    }

    /// Creates and assigns a list of `DayEventCardModel`
    /// that will be displayd on the home screen
    private func createCarouselCards(schedules: [Schedule]) {
        if schedules.isEmpty || schedules.filter({ $0.toggled }).isEmpty {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.status = .loading
        }
        let eventsForToday = schedules.filterEventsMatchingToday()
        
        let todaysEventsCards = eventsForToday.sorted(by: EventSorting.sortedEventOrder).map {
            WeekEventCardModel(event: $0)
        }
        DispatchQueue.main.async { [weak self] in
            self?.todaysEventsCards = todaysEventsCards
            self?.status = .available
        }
    }
    
    deinit {
        cancellables.forEach({ $0.cancel() })
    }
    
}
