//
//  BookmarksViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/21/22.
//

import Combine
import RealmSwift
import SwiftUI

typealias CalendarEvents = [Date : [Event]]

struct BookmarkData {
    let days: [Day]
    let calendarEventsByDate: CalendarEvents
    let weeks: [Int : [Day]]
}

final class BookmarksViewModel: ObservableObject {
    let viewModelFactory: ViewModelFactory = .shared
    let appController: AppController = .shared
    let scheduleViewTypes: [ViewType] = ViewType.allCases
    
    @Inject var preferenceManager: PreferenceManager
    @Inject var schoolManager: SchoolManager
    @Inject var realmManager: RealmManager
    
    @Published var defaultViewType: ViewType {
        didSet {
            self.updatePreferenceViewType()
            if defaultViewType == .list {
                toTopButtonVisible = true
            } else {
                toTopButtonVisible = false
            }
        }
    }
    @Published var viewSwitcherVisible: Bool = true
    @Published var toTopButtonVisible: Bool = false
    @Published var eventSheet: EventDetailsSheetModel? = nil
    @Published var status: BookmarksViewStatus = .loading
    @Published var bookmarkData: BookmarkData = BookmarkData(days: [], calendarEventsByDate: [:], weeks: [:])
    
    private var schedulesToken: NotificationToken? = nil
    private var workItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        defaultViewType = .list
        defaultViewType = ViewType.allCases[preferenceManager.viewTypeIndex]
        setupPublishers()
    }

    private func setupPublishers() {
        let updatingBookmarksPublisher = appController.$isUpdatingBookmarks.receive(on: RunLoop.main)
        updatingBookmarksPublisher.sink { [weak self] updatingBookmarks in
            if !updatingBookmarks {
                self?.setupRealmListener()
            }
        }
        .store(in: &cancellables)
    }
    
    private func setupRealmListener() {
        let schedules = realmManager.getAllLiveSchedules()
        schedulesToken = schedules.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(let results), .update(let results, _, _, _):
                self.workItem?.cancel()
                self.workItem = DispatchWorkItem { [weak self] in
                    self?.createDaysAndCalendarEvents(schedules: Array(results))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: self.workItem!)
            case .error:
                DispatchQueue.main.async {
                    self.setStatusOnMainThread(to: .error)
                }
            }
        }
    }
    
    
    func toggleViewSwitcherVisibility() {
        withAnimation {
            viewSwitcherVisible.toggle()
        }
    }
    
    /// Instantiates viewmodel for viewing a specific `Event` object
    func createViewModelEventSheet(event: Event) -> EventDetailsSheetViewModel {
        return viewModelFactory.makeViewModelEventDetailsSheet(event: event)
    }
    
    func setViewType(viewType: ViewType) {
        self.defaultViewType = viewType
    }
    
    private func updatePreferenceViewType() {
        let viewTypeIndex: Int = scheduleViewTypes.firstIndex(of: defaultViewType)!
        preferenceManager.viewTypeIndex = viewTypeIndex
    }
    
    /// Creates any calendar and list events, parsing through the schedules that
    /// should not be visible or any schedules that have missing events
    private func createDaysAndCalendarEvents(schedules: [Schedule]) {
        
        setStatusOnMainThread(to: .loading)
        
        let hiddenScheduleIds = extractHiddenScheduleIds(from: schedules)
        let visibleSchedules = extractVisibleSchedules(from: schedules)

        if schedules.isEmpty {
            setStatusOnMainThread(to: .uninitialized)
            return
        }
        
        if areAllSchedulesHidden(schedules: schedules) {
            setStatusOnMainThread(to: .hiddenAll)
            return
        }
        
        if areVisibleSchedulesEmpty(visibleSchedules: visibleSchedules) {
            setStatusOnMainThread(to: .empty)
            return
        }
        
        let days = processSchedules(schedules: schedules, hiddenScheduleIds: hiddenScheduleIds)
        let calendarEvents = makeCalendarEvents(days: days)
        
        updateView(with: days, calendarEvents: calendarEvents)
    }

    // MARK: - Helper Functions

    private func setStatusOnMainThread(to status: BookmarksViewStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.status = status
        }
    }

    private func extractHiddenScheduleIds(from schedules: [Schedule]) -> [String] {
        return schedules.filter { !$0.toggled }.map { $0.scheduleId }
    }

    private func extractVisibleSchedules(from schedules: [Schedule]) -> [Schedule] {
        return schedules.filter { $0.toggled }
    }

    private func areAllSchedulesHidden(schedules: [Schedule]) -> Bool {
        return schedules.allSatisfy { !$0.toggled }
    }

    private func areVisibleSchedulesEmpty(visibleSchedules: [Schedule]) -> Bool {
        return visibleSchedules.allSatisfy { $0.isMissingEvents() }
    }

    private func processSchedules(schedules: [Schedule], hiddenScheduleIds: [String]) -> [Day] {
        return filterHiddenBookmarks(schedules: schedules, hiddenBookmarks: hiddenScheduleIds)
            .flattenAndMerge()
            .ordered()
            .filterEmptyDays()
            .filterValidDays()
    }

    private func updateView(with days: [Day], calendarEvents: CalendarEvents) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            AppLogger.shared.debug("Updating days ..", file: "BookmarksViewModel")
            self.bookmarkData = BookmarkData(days: days, calendarEventsByDate: calendarEvents, weeks: days.groupedByWeeks())
            self.setStatusOnMainThread(to: .loaded)
        }
    }

    
    /// Checks if all schedules the user has bookmarked are toggled as `False`
    private func allSchedulesHidden(schedules: [Schedule]) -> Bool {
        return schedules.filter({ $0.toggled }).isEmpty
    }
    
    /// Creates events for the `.calendar` viewtype
    private func makeCalendarEvents(days: [Day]) -> [Date: [Event]] {
        var dict = [Date: [Event]]()
        for day in days {
            for event in day.events {
                if let date = dateFormatterEvent.date(from: event.from) {
                    let normalizedDate = Calendar.current.startOfDay(for: date)
                    if dict[normalizedDate] == nil {
                        dict[normalizedDate] = [event]
                    } else {
                        dict[normalizedDate]?.append(event)
                    }
                }
            }
        }
        return dict
    }
}
