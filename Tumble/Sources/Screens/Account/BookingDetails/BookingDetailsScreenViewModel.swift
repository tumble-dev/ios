//
//  BookingDetailsScreenViewModel.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-05.
//

import Combine
import Foundation

typealias BookingDetailsScreenViewModelType = StateStoreViewModel<BookingDetailsScreenViewState, BookingDetailsScreenViewAction>

class BookingDetailsScreenViewModel: BookingDetailsScreenViewModelType, BookingDetailsScreenViewModelProtocol {
    private let originalBooking: Response.Booking
    private let school: String
    private let tumbleApiService: TumbleApiServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    
    private var actionsSubject: PassthroughSubject<BookingDetailsScreenViewModelAction, Never> = .init()
    
    // Tasks for network operations that can be cancelled
    private var confirmBookingTask: Task<Void, Never>?
    private var cancelBookingTask: Task<Void, Never>?
    
    var actions: AnyPublisher<BookingDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        booking: Response.Booking,
        school: String,
        tumbleApiService: TumbleApiServiceProtocol,
        authenticationService: AuthenticationServiceProtocol
    ) {
        originalBooking = booking
        self.school = school
        self.tumbleApiService = tumbleApiService
        self.authenticationService = authenticationService
        super.init(initialViewState: .init(booking: booking))
    }
    
    deinit {
        // Cancel any ongoing network tasks when the view model is deallocated
        confirmBookingTask?.cancel()
        cancelBookingTask?.cancel()
        AppLogger.shared.info("[BookingDetailsScreenViewModel] Deallocated and cancelled ongoing tasks")
    }
    
    override func process(viewAction: BookingDetailsScreenViewAction) {
        switch viewAction {
        case .loadBooking:
            loadBookingDetails()
        case .confirmBooking:
            // Cancel any existing confirmation task before starting a new one
            confirmBookingTask?.cancel()
            confirmBookingTask = Task { await confirmBooking() }
        case .cancelBooking:
            showCancellationAlert()
        case .confirmCancellation:
            // Cancel any existing cancellation task before starting a new one
            cancelBookingTask?.cancel()
            cancelBookingTask = Task { await cancelBooking() }
        case .dismissAlert:
            hideCancellationAlert()
        case .close:
            // Cancel ongoing tasks when user manually closes
            confirmBookingTask?.cancel()
            cancelBookingTask?.cancel()
            actionsSubject.send(.dismiss)
        }
    }
    
    private func loadBookingDetails() {
        updateDataState(newState: .loaded(originalBooking))
    }
    
    private func confirmBooking() async {
        // Check if the task was cancelled before starting
        guard !Task.isCancelled else {
            AppLogger.shared.info("[BookingDetailsScreenViewModel] Confirm booking task was cancelled")
            return
        }
        
        Task { @MainActor in
            updateDataState(newState: .loading)
        }
        
        do {
            // Check cancellation before each async operation
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Confirm booking task cancelled during token fetch")
                return
            }
            
            let token = try await authenticationService.getCurrentSessionToken()
            
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Confirm booking task cancelled after token fetch")
                return
            }
            
            _ = try await tumbleApiService.confirmResourceBooking(
                bookingId: originalBooking.id,
                school: school,
                authToken: token
            )
            
            // Check cancellation before updating UI
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Confirm booking task cancelled after API call")
                return
            }
            
            let confirmedBooking = Response.Booking(
                id: originalBooking.id,
                resourceId: originalBooking.resourceId,
                timeSlot: originalBooking.timeSlot,
                locationId: originalBooking.locationId,
                showConfirmButton: false,
                showUnbookButton: originalBooking.showUnbookButton,
                confirmationOpen: originalBooking.confirmationOpen,
                confirmationClosed: originalBooking.confirmationClosed
            )
            
            Task { @MainActor in
                updateDataState(newState: .loaded(confirmedBooking))
                updateBooking(confirmedBooking)
                actionsSubject.send(.bookingConfirmed)
            }
            
            AppLogger.shared.info("[BookingDetailsScreenViewModel] Successfully confirmed booking \(originalBooking.id)")
            
        } catch is CancellationError {
            AppLogger.shared.info("[BookingDetailsScreenViewModel] Confirm booking task was cancelled")
        } catch {
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Confirm booking task cancelled during error handling")
                return
            }
            
            AppLogger.shared.error("[BookingDetailsScreenViewModel] Failed to confirm booking: \(error)")
            Task { @MainActor in
                updateDataState(newState: .error("Failed to confirm booking: \(error.localizedDescription)"))
            }
        }
    }
    
    private func cancelBooking() async {
        // Check if the task was cancelled before starting
        guard !Task.isCancelled else {
            AppLogger.shared.info("[BookingDetailsScreenViewModel] Cancel booking task was cancelled")
            return
        }
        
        Task { @MainActor in
            updateDataState(newState: .loading)
        }
        
        do {
            // Check cancellation before each async operation
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Cancel booking task cancelled during token fetch")
                return
            }
            
            let token = try await authenticationService.getCurrentSessionToken()
            
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Cancel booking task cancelled after token fetch")
                return
            }
            
            _ = try await tumbleApiService.unbookResource(
                bookingId: originalBooking.id,
                school: school,
                authToken: token
            )
            
            // Check cancellation before sending success action
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Cancel booking task cancelled after API call")
                return
            }
            
            // Send success action which will trigger dismissal and return to account screen
            Task { @MainActor in
                actionsSubject.send(.bookingCancelled)
            }
            
            AppLogger.shared.info("[BookingDetailsScreenViewModel] Successfully cancelled booking \(originalBooking.id)")
            
        } catch is CancellationError {
            AppLogger.shared.info("[BookingDetailsScreenViewModel] Cancel booking task was cancelled")
        } catch {
            guard !Task.isCancelled else {
                AppLogger.shared.info("[BookingDetailsScreenViewModel] Cancel booking task cancelled during error handling")
                return
            }
            
            AppLogger.shared.error("[BookingDetailsScreenViewModel] Failed to cancel booking: \(error)")
            Task { @MainActor in
                updateDataState(newState: .error("Failed to cancel booking: \(error.localizedDescription)"))
            }
        }
        
        hideCancellationAlert()
    }
    
    private func showCancellationAlert() {
        state.showConfirmationAlert = true
    }
    
    private func hideCancellationAlert() {
        state.showConfirmationAlert = false
    }
    
    @MainActor
    private func updateDataState(newState: BookingDetailsScreenDataState) {
        state.dataState = newState
    }
    
    @MainActor
    private func updateBooking(_ booking: Response.Booking) {
        state.booking = booking
    }
}
