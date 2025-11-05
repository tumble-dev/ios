//
//  AccountFlowCoordinatorStateMachine.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-04.
//

import Combine
import Foundation
import SwiftState

class AccountFlowCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the coordinator starts
        case initial
                
        /// Showing the account screen
        case accountScreen
        
        /// Showing resource details screen
        case resourceDetailsScreen(resourceId: String)
        
        /// Showing the resource selection screen
        case resourceSelectionScreen
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    /// Events that can be triggered on the MainCoordinator state machine
    enum Event: EventType {
        /// Start the main flows.
        case start
        
        /// Request presentation of the resource selection screen.
        case showResourceSelectionScreen
        /// The resource selection screen has been dismissed.
        case dismissedResourceSelectionScreen
        
        // MARK: - Sheets & Fullscreen Covers
        
        /// Request presentation of the resource details screen
        case showResourceDetailsScreen(resourceId: String)
        /// The resource details screen has been dismissed
        case dismissedResourceDetailsScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: AccountFlowCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    var stateSubject = PassthroughSubject<State, Never>()
    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .accountScreen])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.accountScreen, .showResourceDetailsScreen(let resourceId)):
                return .resourceDetailsScreen(resourceId: resourceId)

            case (.resourceDetailsScreen, .dismissedResourceDetailsScreen):
                return .accountScreen
                  
            case (.accountScreen, .showResourceSelectionScreen):
                return .resourceSelectionScreen
            
            case (.resourceSelectionScreen, .dismissedResourceSelectionScreen):
                return .accountScreen
    
            default:
                return nil
            }
        }
        
        addTransitionHandler { context in
            if let event = context.event {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                AppLogger.shared.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
        
        addTransitionHandler { [weak self] context in
            self?.stateSubject.send(context.toState)
        }
    }
    
    /// Attempt to move the state machine to another state through an event
    /// It will either invoke the `transitionHandler` or the `errorHandler` depending on its current state
    func processEvent(_ event: Event, userInfo: EventUserInfo? = nil) {
        stateMachine.tryEvent(event, userInfo: userInfo)
    }
    
    /// Registers a callback for processing state machine transitions
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    /// Registers a callback for processing state machine errors
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
    
}
