//
//  NetworkMonitor.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import Foundation
import Network

class NetworkMonitor: NetworkMonitorProtocol {
    private let pathMonitor: NWPathMonitor
    private let queue: DispatchQueue
    
    private let reachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never>
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        reachabilitySubject.asCurrentValuePublisher()
    }
    
    init() {
        queue = DispatchQueue(label: "\(Config.baseBundleIdentifier).network_monitor", qos: .background)
        pathMonitor = NWPathMonitor()
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.reachabilitySubject.send(.reachable)
                } else {
                    self?.reachabilitySubject.send(.unreachable)
                }
            }
        }
        pathMonitor.start(queue: queue)
    }
}
