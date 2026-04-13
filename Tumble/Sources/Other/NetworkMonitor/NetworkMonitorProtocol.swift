//
//  NetworkMonitorProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

enum NetworkMonitorReachability {
    case reachable(connectionType: NetworkConnectionType)
    case unreachable
    
    // Convenience properties for backwards compatibility
    var isReachable: Bool {
        switch self {
        case .reachable:
            return true
        case .unreachable:
            return false
        }
    }
    
    var isWifiOrWired: Bool {
        switch self {
        case .reachable(let connectionType):
            return connectionType == .wifi || connectionType == .wiredEthernet
        case .unreachable:
            return false
        }
    }
}

enum NetworkConnectionType {
    case wifi
    case cellular
    case wiredEthernet
    case other
}

protocol NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> { get }
}
