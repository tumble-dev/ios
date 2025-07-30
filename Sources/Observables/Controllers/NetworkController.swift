//
//  NetworkController.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-08-27.
//

import Network
import SwiftUI

class NetworkController: ObservableObject {
    static let shared: NetworkController = .init()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Network monitor")
    @Published private(set) var connected: Bool = false
    
    init() {
        checkConnection()
    }
    
    private func checkConnection() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.connected = true
                } else {
                    self?.connected = false
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}
