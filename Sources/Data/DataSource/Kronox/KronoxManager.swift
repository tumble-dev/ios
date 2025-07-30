//
//  NetworkManager.swift
//  ios-tumble
//
//  Created by Adis Veletanlic on 11/15/22.
//

import Foundation

enum KronoxManagerError: LocalizedError {
    case generic(String)
    case badServerResponse
    case wrongStatusCode
    case emptyResponse
    case decodingError
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .generic(let reason):
            return reason
        case .badServerResponse, .wrongStatusCode:
            return NSLocalizedString("Bad server response.", comment: "")
        case .emptyResponse:
            return NSLocalizedString("The server seems to be offline", comment: "")
        case .decodingError:
            return NSLocalizedString("Something went wrong on our end", comment: "")
        case .noInternetConnection:
            return NSLocalizedString("Not connected to the internet.", comment: "")
        }
    }
}


class KronoxManager {
    private let urlRequestUtils = NetworkUtilities.shared
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    func get<NetworkResponse: Decodable>(
        _ endpoint: Endpoint,
        refreshToken: String? = nil,
        sessionDetails: String? = nil
    ) async throws -> NetworkResponse {
        let urlRequest = try makeUrlRequest(
            method: .get,
            endpoint: endpoint,
            refreshToken: refreshToken,
            sessionDetails: sessionDetails,
            body: nil as String?
        )
        return try await executeRequest(urlRequest, .get)
    }
    
    func put<NetworkResponse : Decodable, Request : Encodable>(
        _ endpoint: Endpoint,
        refreshToken: String? = nil,
        sessionDetails: String? = nil,
        body: Request? = nil
    ) async throws -> NetworkResponse {
        let urlRequest = try makeUrlRequest(
            method: .put,
            endpoint: endpoint,
            refreshToken: refreshToken,
            sessionDetails: sessionDetails,
            body: body
        )
        return try await executeRequest(urlRequest, .put)
    }
    
    private func makeUrlRequest<Request : Encodable>(
        method: Method,
        endpoint: Endpoint,
        refreshToken: String?,
        sessionDetails: String?,
        body: Request? = nil
    ) throws -> URLRequest {
        return try urlRequestUtils.createTumbleUrlRequest(
            method: method,
            endpoint: endpoint,
            refreshToken: refreshToken,
            body: body
        )
    }
    
    private func executeRequest<NetworkResponse : Decodable>(
        _ urlRequest: URLRequest, _ method: Method
    ) async throws -> NetworkResponse {
        
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KronoxManagerError.badServerResponse
        }
            
        switch httpResponse.statusCode {
        case 200:
            return !data.isEmpty ? try decode(data) : try decodeEmptyResponse()
        case 202:
            return try decodeEmptyResponse()
        default:
            throw KronoxManagerError.wrongStatusCode
        }
    }

    private func decode<NetworkResponse: Decodable>(_ data: Data) throws -> NetworkResponse {
        do {
            return try decoder.decode(NetworkResponse.self, from: data)
        } catch {
            throw KronoxManagerError.decodingError
        }
    }

    private func decodeEmptyResponse<NetworkResponse: Decodable>() throws -> NetworkResponse {
        if let result = Response.Empty() as? NetworkResponse {
            return result
        } else {
            throw KronoxManagerError.emptyResponse
        }
    }
}
