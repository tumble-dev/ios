//
//  WebSocketSessionManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-22.
//

import Foundation
import Combine

// MARK: - WebSocket Message Types

struct WSMessage: Codable {
    let type: String
    let data: AnyCodable?
    
    enum MessageType {
        static let auth = "auth"
        static let authSuccess = "auth_success"
        static let authError = "auth_error"
        static let sessionExpired = "session_expired"
        static let ping = "ping"
        static let pong = "pong"
    }
}

// MARK: - WebSocket Connection State

enum WebSocketState: Equatable {
    case disconnected
    case connecting
    case connected
    case authenticated
    case error(Error)
    
    static func == (lhs: WebSocketState, rhs: WebSocketState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.authenticated, .authenticated):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

// MARK: - WebSocket Session Manager Protocol

protocol WebSocketSessionManagerProtocol {
    var connectionState: WebSocketState { get }
    var connectionStatePublisher: Published<WebSocketState>.Publisher { get }
    
    func connect() async
    func disconnect()
    func authenticate(username: String, password: String, schoolCode: String) async throws -> Response.User
    func isConnected() -> Bool
}

// MARK: - WebSocket Session Manager Implementation

final class WebSocketSessionManager: NSObject, WebSocketSessionManagerProtocol, ObservableObject {
    @Published private(set) var connectionState: WebSocketState = .disconnected
    
    var connectionStatePublisher: Published<WebSocketState>.Publisher { $connectionState }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private let webSocketURL: URL
    private var isReconnecting = false
    private var reconnectTimer: Timer?
    
    // Callbacks for authentication events
    var onSessionExpired: (() -> Void)?
    var onAuthenticationSuccess: ((Response.User) -> Void)?
    var onAuthenticationError: ((String) -> Void)?
    
    init(webSocketURL: URL) {
        self.webSocketURL = webSocketURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
        
        super.init()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    func connect() async {
        guard connectionState != .connecting && connectionState != .connected && connectionState != .authenticated else {
            AppLogger.shared.info("WebSocket already connecting or connected")
            return
        }
        
        await updateConnectionState(.connecting)
        
        var request = URLRequest(url: webSocketURL)
        request.setValue("Tumble-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        startListening()
        
        await updateConnectionState(.connected)
        
        startPingPong()
    }
    
    func disconnect() {
        AppLogger.shared.info("Disconnecting WebSocket")
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        Task { @MainActor in
            connectionState = .disconnected
        }
    }
    
    func isConnected() -> Bool {
        return connectionState == .connected || connectionState == .authenticated
    }
    
    // MARK: - Authentication
    
    private var authContinuation: CheckedContinuation<Response.User, Error>?
    private var isAuthenticating = false

    func authenticate(username: String, password: String, schoolCode: String) async throws -> Response.User {
        guard isConnected() else {
            throw AuthError.noActiveSession
        }
        
        // Prevent concurrent authentication attempts
        guard !isAuthenticating else {
            AppLogger.shared.warning("Authentication already in progress, ignoring duplicate request")
            throw AuthError.requestError
        }
        
        isAuthenticating = true
        defer { isAuthenticating = false }
        let authData = [
            "username": username,
            "password": password,
            "school_code": schoolCode
        ]
        
        let message = WSMessage(
            type: WSMessage.MessageType.auth,
            data: AnyCodable(authData)
        )
        
        try await sendMessage(message)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
        }
    }
    
    // MARK: - Message Handling
    
    private func startListening() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.startListening()
            case .failure(let error):
                AppLogger.shared.error("WebSocket receive error: \(error)")
                Task { [weak self] in
                    await self?.handleConnectionError(error)
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleTextMessage(text)
            }
        @unknown default:
            AppLogger.shared.warning("Unknown WebSocket message type")
        }
    }
    
    private func handleTextMessage(_ text: String) {
        AppLogger.shared.debug("Received WebSocket message: \(text)")
        
        guard let data = text.data(using: .utf8),
              let wsMessage = try? JSONDecoder().decode(WSMessage.self, from: data) else {
            AppLogger.shared.error("Failed to decode WebSocket message: \(text)")
            return
        }
        
        Task { @MainActor in
            await handleWSMessage(wsMessage)
        }
    }
    
    @MainActor
    private func handleWSMessage(_ message: WSMessage) async {
        switch message.type {
        case WSMessage.MessageType.authSuccess:
            AppLogger.shared.info("WebSocket authentication successful")
            connectionState = .authenticated
            
            if let userData = message.data?.value as? [String: Any],
               let username = userData["username"] as? String,
               let name = userData["name"] as? String,
               let sessionId = userData["session_id"] as? String {
                
                let user = Response.User(
                    name: name,
                    sessionId: sessionId,
                    username: username
                )
                
                if let authContinuation = self.authContinuation {
                    self.authContinuation = nil
                    authContinuation.resume(returning: user)
                }
                
                onAuthenticationSuccess?(user)
            } else {
                if let authContinuation = self.authContinuation {
                    self.authContinuation = nil
                    authContinuation.resume(throwing: AuthError.decodingError)
                }
            }
            
        case WSMessage.MessageType.authError:
            AppLogger.shared.error("WebSocket authentication failed")
            
            let errorMessage: String
            if let errorData = message.data?.value as? [String: Any],
               let error = errorData["error"] as? String {
                errorMessage = error
            } else {
                errorMessage = "Authentication failed"
            }
            
            if let authContinuation = self.authContinuation {
                self.authContinuation = nil
                authContinuation.resume(throwing: AuthError.invalidCredentials)
            }
            
            onAuthenticationError?(errorMessage)
            
        case WSMessage.MessageType.sessionExpired:
            AppLogger.shared.warning("WebSocket session expired")
            onSessionExpired?()
            
        case WSMessage.MessageType.pong:
            AppLogger.shared.debug("Received WebSocket pong")
            
        default:
            AppLogger.shared.debug("Unhandled WebSocket message type: \(message.type)")
        }
    }
    
    private func sendMessage(_ message: WSMessage) async throws {
        guard let webSocketTask = webSocketTask else {
            throw AuthError.noActiveSession
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let text = String(data: data, encoding: .utf8) ?? ""
        
        let wsMessage = URLSessionWebSocketTask.Message.string(text)
        
        try await webSocketTask.send(wsMessage)
    }
    
    // MARK: - Connection Health
    
    private func startPingPong() {
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.sendPing()
            }
        }
    }
    
    private func sendPing() async {
        guard isConnected() else { return }
        
        let pingMessage = WSMessage(
            type: WSMessage.MessageType.ping,
            data: nil
        )
        
        do {
            try await sendMessage(pingMessage)
            AppLogger.shared.debug("Sent WebSocket ping")
        } catch {
            AppLogger.shared.error("Failed to send WebSocket ping: \(error)")
            await handleConnectionError(error)
        }
    }
    
    private func handleConnectionError(_ error: Error) async {
        AppLogger.shared.error("WebSocket connection error: \(error)")
        await updateConnectionState(.error(error))
        
        if !isReconnecting {
            isReconnecting = true
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            if connectionState != .disconnected {
                await connect()
            }
            
            isReconnecting = false
        }
    }
    
    @MainActor
    private func updateConnectionState(_ newState: WebSocketState) async {
        connectionState = newState
    }
}

// MARK: - Helper for Any Codable

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                    debugDescription: "Cannot decode AnyCodable"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let stringValue as String:
            try container.encode(stringValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let dictValue as [String: Any]:
            try container.encode(dictValue.compactMapValues { AnyCodable($0) })
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value,
                EncodingError.Context(codingPath: encoder.codingPath,
                                    debugDescription: "Cannot encode value of type \(type(of: value))"))
        }
    }
}
