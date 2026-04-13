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
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.unreachable)
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    let connectionType = self?.determineConnectionType(from: path) ?? .other
                    self?.reachabilitySubject.send(.reachable(connectionType: connectionType))
                } else {
                    self?.reachabilitySubject.send(.unreachable)
                }
            }
        }
        pathMonitor.start(queue: queue)
    }
    
    private func determineConnectionType(from path: NWPath) -> NetworkConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .other
        }
    }
}
