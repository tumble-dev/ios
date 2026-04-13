//
//  NetworkSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-29.
//

import Foundation
import Network

struct NetworkSettings {
    enum Environments {
        static let production = NetworkSettings(
            port: 443, scheme: "https", tumbleUrl: "app.tumbleforkronox.com"
        )
        
        static let development = NetworkSettings(
            port: 7077, scheme: "http", tumbleUrl: Self.getLocalIPAddress() ?? "host.docker.internal"
        )
        
        // Dynamically detect the local IP address
        private static func getLocalIPAddress() -> String? {
            var address: String?
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            
            if getifaddrs(&ifaddr) == 0 {
                var ptr = ifaddr
                while ptr != nil {
                    defer { ptr = ptr?.pointee.ifa_next }
                    
                    guard let interface = ptr?.pointee else { continue }
                    let addrFamily = interface.ifa_addr.pointee.sa_family
                    
                    if addrFamily == UInt8(AF_INET) {
                        let name = String(cString: interface.ifa_name)
                        if name == "en0" { // WiFi interface
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                        &hostname, socklen_t(hostname.count),
                                        nil, socklen_t(0), NI_NUMERICHOST)
                            address = String(cString: hostname)
                        }
                    }
                }
                freeifaddrs(ifaddr)
            }
            
            return address
        }
    }

    let port: Int
    let scheme: String
    let tumbleUrl: String
}
