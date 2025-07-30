//
//  SearchPreviewViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/14/23.
//

import Combine
import Foundation
import RealmSwift

final class SearchPreviewViewModel: ObservableObject {
    
    @Inject private var preferenceManager: PreferenceManager
    @Inject private var kronoxManager: KronoxManager
    @Inject private var notificationManager: NotificationManager
    @Inject private var schoolManager: SchoolManager
    @Inject private var realmManager: RealmManager
    
    @Published var isSaved = false
    @Published var status: SchedulePreviewStatus = .loading
    @Published var bookmarks: [Bookmark]?
    @Published var errorMessage: String? = nil
    @Published var buttonState: ButtonState = .loading
    @Published var courseColorsForPreview: [String: String] = [:]
    
    var schedule: Response.Schedule? = nil
    private lazy var schools: [School] = schoolManager.getSchools()
    
    /// Retrieve the schedule that was pressed on
    /// from the list of search results
    func getSchedule(programmeId: String, schoolId: String, schedules: [Schedule]) {
        let isScheduleSaved = self.checkSavedSchedule(programmeId: programmeId, schedules: schedules)
        DispatchQueue.main.async { [weak self] in
            self?.status = .loading
            self?.isSaved = isScheduleSaved
        }

        Task {
            do {
                let endpoint: Endpoint = .schedule(scheduleId: programmeId, schoolId: schoolId)
                let fetchedSchedule: Response.Schedule = try await kronoxManager.get(endpoint)
                self.updateUIWithFetchedSchedule(fetchedSchedule, existingSchedules: schedules)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.status = .error
                    if let error = error as? KronoxManagerError {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.errorMessage = NSLocalizedString("An unexpected error occurred. Please try again later.", comment: "")
                    }
                    AppLogger.shared.debug("Error occured: \(error)")
                }
            }
        }
    }
    
    /// Perform UI updates based on the retrieved schedule data
    private func updateUIWithFetchedSchedule(_ fetchedSchedule: Response.Schedule, existingSchedules: [Schedule]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !fetchedSchedule.hasEvents {
                self.status = .empty
                self.buttonState = .disabled
            } else if (existingSchedules.map { $0.scheduleId }).contains(fetchedSchedule.id) {
                self.isSaved = true
                self.buttonState = .saved
                self.schedule = fetchedSchedule
                self.courseColorsForPreview = self.realmManager.getCourseColors()
                self.status = .loaded
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let randomCourseColors = fetchedSchedule.assignCoursesRandomColors()
                    DispatchQueue.main.async {
                        // Assign possibly updated course colors
                        self.courseColorsForPreview = randomCourseColors
                        self.schedule = fetchedSchedule
                        self.buttonState = .notSaved
                        self.status = .loaded
                    }
                }
            }
        }
    }

    
    func scheduleRequiresAuth(schoolId: String) -> Bool {
        schools.first(where: { $0.id == Int(schoolId) })?.loginRq ?? false
    }
    
    @MainActor func bookmark(
        scheduleId: String,
        schedules: [Schedule],
        schoolId: String,
        scheduleTitle: String
    ) {
        buttonState = .loading
        // If the schedule isn't already saved in the local database
        if !isSaved {
            if let realmSchedule = schedule?.toRealmSchedule(
                scheduleRequiresAuth: scheduleRequiresAuth(schoolId: schoolId), schoolId: schoolId, scheduleTitle: scheduleTitle
            ) {
                realmManager.saveSchedule(schedule: realmSchedule)
                isSaved = true
                buttonState = .saved
            }
        }
        // Otherwise we remove (untoggle) the schedule
        else {
            let realmSchedule = realmManager.getScheduleByScheduleId(scheduleId: scheduleId)
            if let realmSchedule = realmSchedule {
                realmManager.deleteSchedule(schedule: realmSchedule)
                isSaved = false
                buttonState = .notSaved
            }
        }
    }
    
    // Checks if a schedule based on its programme Id is already in the
    // local storage. if it is, we set the preview button for favoriting
    // to be either save or remove.
    func checkSavedSchedule(programmeId: String, schedules: [Schedule]) -> Bool {
        AppLogger.shared.debug("Checking if schedule is already saved...")
        if schedules.map({ $0.scheduleId }).contains(programmeId) {
            return true
        }
        return false
    }
}
