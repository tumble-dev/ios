//
//  ApplicationCoordinatorStateMachine.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation
import SwiftState

class ApplicationCoordinatorStateMachine {
    
    enum State: StateType {
        case initial
        case ready
    }


    enum Event: EventType {
        case start
        case clearCache
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: ApplicationCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .ready])
        stateMachine.addRoutes(event: .clearCache, transitions: [.ready => .initial])

        addTransitionHandler { context in
            if let event = context.event {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                AppLogger.shared.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
    }
    
    func processEvent(_ event: Event) {
        stateMachine.tryEvent(event)
    }
    
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
}
