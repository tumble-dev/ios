//
//  AccountScreenViewModelProtool.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine

@MainActor
protocol AccountScreenViewModelProtocol {
    var actions: AnyPublisher<AccountScreenViewModelAction, Never> { get }
    var context: AccountScreenViewModelType.Context { get }
}
