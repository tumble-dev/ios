//
//  SettingsViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-08.
//

import Combine
import Foundation
import RealmSwift
import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Inject var preferenceManager: PreferenceManager
    @Inject var notificationManager: NotificationManager
    @Inject var schoolManager: SchoolManager
    @Inject var realmManager: RealmManager
    @Inject var githubApiManager: GithubApiManager
    
    @Published var bookmarks: [Bookmark]?
    @Published var presentSidebarSheet: Bool = false
    @Published var authStatus: AuthStatus = .unAuthorized
    @Published var contributorPageStatus: GenericPageStatus = .loading
    @Published var schoolName: String = ""
    @Published var contributors: [Contributor] = []
    
    @Published var authSchoolId: Int = -1
    @Published var appearance: AppearanceType = AppearanceType.system {
        didSet {
            if oldValue != appearance {
                self.setAppearance(appearance: appearance)
            }
        }
    }
    @Published var notificationOffset: NotificationOffset = .hour {
        didSet {
            if oldValue != notificationOffset {
                self.rescheduleNotifications(previousOffset: oldValue.rawValue, newOffset: notificationOffset.rawValue)
                self.setNotificationOffset(offset: notificationOffset)
            }
        }
    }
    @Published var openEventFromWidget: Bool = true {
        didSet {
            if oldValue != openEventFromWidget {
                self.setOpenEventFromWidget(value: openEventFromWidget)
            }
        }
    }
    
    let popupFactory: PopupFactory = PopupFactory.shared
    private let userController: UserController = .shared
    private lazy var schools: [School] = schoolManager.getSchools()
    private var cancellables: Set<AnyCancellable> = []
    private var cancellableTask: Task<Void, Never>?
    
    init() { setUpDataPublishers() }
    
    private func setUpDataPublishers() {
        
        let authSchoolIdPublisher = preferenceManager.$authSchoolId.receive(on: RunLoop.main)
        let appearancePublisher = preferenceManager.$appearance.receive(on: RunLoop.main)
        let notificationOffsetPublisher = preferenceManager.$notificationOffset.receive(on: RunLoop.main)
        let openEventFromWidgetPublisher = preferenceManager.$openEventFromWidget.receive(on: RunLoop.main)
        let authStatusPublisher = userController.$authStatus.receive(on: RunLoop.main)
        
        Publishers.CombineLatest3(authSchoolIdPublisher, appearancePublisher, notificationOffsetPublisher)
            .sink { [weak self] authSchoolId, appearance, notificationOffset in
                self?.authSchoolId = authSchoolId
                self?.notificationOffset = notificationOffset
                self?.appearance = appearance
                
                self?.schoolName = self?.schools.first(where: { $0.id == authSchoolId })?.name ?? ""
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(authStatusPublisher, openEventFromWidgetPublisher)
            .sink { [weak self] authStatus, openEventFromWidget in
                self?.authStatus = authStatus
                self?.openEventFromWidget = openEventFromWidget
            }
            .store(in: &cancellables)
    }
    
    func getRepoContributors() {
        if !contributors.isEmpty {
            return
        }
            
        cancellableTask?.cancel()
        cancellableTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let contributors = try await self?.githubApiManager.getRepoContributors()
                DispatchQueue.main.async { [weak self] in
                    AppLogger.shared.debug("Retrieved all contributors")
                    self?.contributors = contributors ?? []
                    self?.contributorPageStatus = .loaded
                }
            } catch {
                AppLogger.shared.debug("Error retrieving contributors: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.contributorPageStatus = .error
                }
            }
        }
    }
    
    func cancelContributorFetch() {
        cancellableTask?.cancel()
        AppLogger.shared.debug("Contributor fetch task cancelled")
    }
    
    func removeNotifications(for id: String, referencing events: [Event]) {
        events.forEach { notificationManager.cancelNotification(for: $0.eventId) }
    }
    
    func clearAllNotifications() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.notificationManager.cancelNotifications()
        }
        PopupToast(popup: popupFactory.clearNotificationsAllEventsSuccess()).showAndStack()
    }
    
    func rescheduleNotifications(previousOffset: Int, newOffset: Int) {
        Task {
            do {
                try await notificationManager.rescheduleEventNotifications(
                    previousOffset: previousOffset,
                    userOffset: newOffset
                )
            } catch {
                // TODO: Show toast
                AppLogger.shared.error("Could not reschedule notifications")
            }
        }
    }
    
    func scheduleNotificationsForAllEvents(allEvents: [Event]) async {
        guard !allEvents.isEmpty else {
            PopupToast(popup: popupFactory.setNotificationsAllEventsFailed()).showAndStack()
            return
        }
        
        let totalNotifications = allEvents.count
        var scheduledNotifications = 0
        
        for event in allEvents {
            guard let notification = notificationManager.createNotificationFromEvent(
                event: event
            ) else {
                AppLogger.shared.error("Could not set notification for event \(event._id)")
                PopupToast(popup: popupFactory.setNotificationsAllEventsFailed()).showAndStack()
                return
            }
            
            do {
                try await notificationManager.scheduleNotification(
                    for: notification,
                    type: .event,
                    userOffset: preferenceManager.notificationOffset.rawValue
                )
                scheduledNotifications += 1
                AppLogger.shared.debug("One notification set")
                
                if scheduledNotifications == totalNotifications {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        PopupToast(popup: self.popupFactory.setNotificationsAllEventsSuccess()).showAndStack()
                    }
                }
            } catch let failure {
                AppLogger.shared.error("\(failure)")
                // TODO: Show toast
            }
        }
    }
    
    func setAppearance(appearance: AppearanceType) {
        preferenceManager.appearance = appearance
    }
    
    func setNotificationOffset(offset: NotificationOffset) {
        preferenceManager.notificationOffset = offset
    }

    func setOpenEventFromWidget(value: Bool) {
        preferenceManager.openEventFromWidget = value
    }
    
    func deleteBookmark(schedule: Schedule) {
        realmManager.deleteSchedule(schedule: schedule)
    }
    
    private func deleteAllSchedules() {
        realmManager.deleteAllSchedules()
    }
    
    deinit {
        cancellableTask?.cancel()
        cancellables.forEach { $0.cancel() }
    }

}
