//
//  NetworkMonitorProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

enum NetworkMonitorReachability {
    case reachable
    case unreachable
}

protocol NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> { get }
}
