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
    
    var actions: AnyPublisher<BookingDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        booking: Response.Booking,
        school: String,
        tumbleApiService: TumbleApiServiceProtocol,
        authenticationService: AuthenticationServiceProtocol
    ) {
        self.originalBooking = booking
        self.school = school
        self.tumbleApiService = tumbleApiService
        self.authenticationService = authenticationService
        super.init(initialViewState: .init(booking: booking))
    }
    
    override func process(viewAction: BookingDetailsScreenViewAction) {
        switch viewAction {
        case .loadBooking:
            loadBookingDetails()
        case .confirmBooking:
            Task { await confirmBooking() }
        case .cancelBooking:
            showCancellationAlert()
        case .confirmCancellation:
            Task { await cancelBooking() }
        case .dismissAlert:
            hideCancellationAlert()
        case .close:
            actionsSubject.send(.dismiss)
        }
    }
    
    private func loadBookingDetails() {
        updateDataState(newState: .loaded(originalBooking))
    }
    
    private func confirmBooking() async {
        do {
            let token = try await authenticationService.getCurrentSessionToken()
            

            try await tumbleApiService.confirmResourceBooking(
                bookingId: self.originalBooking.id,
                school: "hkr",
                authToken: token
            )
            
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
            
            updateDataState(newState: .loaded(confirmedBooking))
            updateBooking(confirmedBooking)
            actionsSubject.send(.bookingConfirmed)
            
        } catch {
            AppLogger.shared.error("Failed to confirm booking: \(error)")
            updateDataState(newState: .error("Failed to confirm booking: \(error.localizedDescription)"))
        }
    }
    
    private func cancelBooking() async {
        do {
            let token = try await authenticationService.getCurrentSessionToken()
            try await tumbleApiService.unbookResource(
                bookingId: originalBooking.id,
                school: school,
                authToken: token
            )
            
            actionsSubject.send(.bookingCancelled)
            
        } catch {
            AppLogger.shared.error("Failed to cancel booking: \(error)")
            updateDataState(newState: .error("Failed to cancel booking: \(error.localizedDescription)"))
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

