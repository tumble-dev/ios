//
//  CurrentValuePublisher.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine

struct CurrentValuePublisher<Output, Failure: Error>: Publisher {
    private let subject: CurrentValueSubject<Output, Failure>
    
    init(_ subject: CurrentValueSubject<Output, Failure>) {
        self.subject = subject
    }
    
    init(_ value: Output) {
        self.init(CurrentValueSubject(value))
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    var value: Output {
        subject.value
    }
}

extension CurrentValueSubject {
    func asCurrentValuePublisher() -> CurrentValuePublisher<Output, Failure> {
        .init(self)
    }
}
