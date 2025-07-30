//
//  URLSession.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-25.
//

import Foundation

extension URLSession {
    static let shared: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        config.httpShouldUsePipelining = true
        // config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
}
