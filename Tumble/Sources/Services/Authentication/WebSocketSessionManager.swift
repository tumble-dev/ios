//
//  WebSocketSessionManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-22.
//

import Combine
import Foundation
import UIKit

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

// MARK: - WebSocket Session Manager Delegate

protocol WebSocketSessionManagerDelegate: AnyObject {
    func webSocketSessionManager(_ manager: WebSocketSessionManager, shouldReauthenticateOnForeground user: Response.User) -> Bool
    func webSocketSessionManager(_ manager: WebSocketSessionManager, credentialsForReauthentication user: Response.User) -> (username: String, password: String, schoolCode: String)?
    func webSocketSessionManager(_ manager: WebSocketSessionManager, didFailReauthenticationWithError error: Error)
    func webSocketSessionManager(_ manager: WebSocketSessionManager, didSucceedReauthentication user: Response.User)
}

// MARK: - WebSocket Session Manager Protocol

protocol WebSocketSessionManagerProtocol {
    var connectionState: WebSocketState { get }
    var connectionStatePublisher: Published<WebSocketState>.Publisher { get }
    var delegate: WebSocketSessionManagerDelegate? { get set }
    
    func connect() async
    func disconnect()
    func authenticate(username: String, password: String, schoolCode: String) async throws -> Response.User
    func isConnected() -> Bool
    func clearStoredAuthentication()
}

// MARK: - WebSocket Session Manager Implementation

final class WebSocketSessionManager: NSObject, WebSocketSessionManagerProtocol, ObservableObject {
    @Published private(set) var connectionState: WebSocketState = .disconnected
    
    var connectionStatePublisher: Published<WebSocketState>.Publisher { $connectionState }
    
    // Delegate for app lifecycle events
    weak var delegate: WebSocketSessionManagerDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private let webSocketURL: URL
    private var isReconnecting = false
    private var reconnectTimer: Timer?
    
    // Store last successful authentication details for re-authentication
    private var lastAuthenticatedUser: Response.User?
    
    // App lifecycle management
    private var cancellables = Set<AnyCancellable>()
    private var isInBackground = false
    
    // Callbacks for authentication events
    var onSessionExpired: (() -> Void)?
    var onAuthenticationSuccess: ((Response.User) -> Void)?
    var onAuthenticationError: ((String) -> Void)?
    
    init(webSocketURL: URL) {
        self.webSocketURL = webSocketURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: config)
        
        super.init()
        
        setupAppLifecycleNotifications()
    }
    
    deinit {
        disconnect()
        cancellables.removeAll()
    }
    
    // MARK: - App Lifecycle Management
    
    private func setupAppLifecycleNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.handleAppWillEnterForeground()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppWillEnterForeground() async {
        AppLogger.shared.info("WebSocketSessionManager: App entering foreground")
        isInBackground = false
        
        // Re-establish connection if needed
        if connectionState == .disconnected {
            await connect()
        }
        
        // Check if we need to re-authenticate
        guard let lastUser = lastAuthenticatedUser else {
            AppLogger.shared.info("WebSocketSessionManager: No stored user for re-authentication")
            return
        }
        
        // Check with delegate if we should re-authenticate
        guard delegate?.webSocketSessionManager(self, shouldReauthenticateOnForeground: lastUser) != false else {
            AppLogger.shared.info("WebSocketSessionManager: Delegate declined re-authentication")
            return
        }
        
        // Only re-authenticate if we're connected but not authenticated
        if connectionState == .connected {
            AppLogger.shared.info("WebSocketSessionManager: Re-authenticating after foreground transition")
            
            // Get fresh credentials from delegate
            guard let credentials = delegate?.webSocketSessionManager(self, credentialsForReauthentication: lastUser) else {
                AppLogger.shared.warning("WebSocketSessionManager: No credentials available for re-authentication")
                return
            }
            
            do {
                let user = try await authenticate(
                    username: credentials.username,
                    password: credentials.password,
                    schoolCode: credentials.schoolCode
                )
                delegate?.webSocketSessionManager(self, didSucceedReauthentication: user)
                AppLogger.shared.info("WebSocketSessionManager: Re-authentication successful")
            } catch {
                AppLogger.shared.error("WebSocketSessionManager: Re-authentication failed: \(error)")
                delegate?.webSocketSessionManager(self, didFailReauthenticationWithError: error)
            }
        }
    }
    
    private func handleAppDidEnterBackground() {
        AppLogger.shared.info("WebSocketSessionManager: App entering background")
        isInBackground = true
        
        // Note: We don't disconnect here as the system will handle WebSocket lifecycle
        // The connection will be terminated by iOS when the app is backgrounded
        // and we'll handle reconnection when the app returns to foreground
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
        
        // Clear stored authentication details when explicitly disconnecting
        // (but not during background transitions)
        if !isInBackground {
            lastAuthenticatedUser = nil
        }
        
        Task { @MainActor in
            connectionState = .disconnected
        }
    }
    
    func isConnected() -> Bool {
        return connectionState == .connected || connectionState == .authenticated
    }
    
    func clearStoredAuthentication() {
        AppLogger.shared.info("WebSocketSessionManager: Clearing stored authentication details")
        lastAuthenticatedUser = nil
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
        guard let data = text.data(using: .utf8),
              let wsMessage = try? JSONDecoder().decode(WSMessage.self, from: data)
        else {
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
               let sessionId = userData["session_id"] as? String
            {
                let user = Response.User(
                    name: name,
                    sessionId: sessionId,
                    username: username
                )
                
                // Store the authenticated user for potential re-authentication
                lastAuthenticatedUser = user
                
                if let authContinuation = authContinuation {
                    self.authContinuation = nil
                    authContinuation.resume(returning: user)
                }
                
                onAuthenticationSuccess?(user)
            } else {
                if let authContinuation = authContinuation {
                    self.authContinuation = nil
                    authContinuation.resume(throwing: AuthError.decodingError)
                }
            }
            
        case WSMessage.MessageType.authError:
            AppLogger.shared.error("WebSocket authentication failed")
            
            let errorMessage: String
            if let errorData = message.data?.value as? [String: Any],
               let error = errorData["error"] as? String
            {
                errorMessage = error
            } else {
                errorMessage = "Authentication failed"
            }
            
            if let authContinuation = authContinuation {
                self.authContinuation = nil
                authContinuation.resume(throwing: AuthError.invalidCredentials)
            }
            
            onAuthenticationError?(errorMessage)
            
        case WSMessage.MessageType.sessionExpired:
            AppLogger.shared.warning("WebSocket session expired")
            onSessionExpired?()
            
        case WSMessage.MessageType.pong:
            AppLogger.shared.info("Received WebSocket pong")
            
        default:
            AppLogger.shared.info("Unhandled WebSocket message type: \(message.type)")
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
            AppLogger.shared.info("Sent WebSocket ping")
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
            
            try? await Task.sleep(nanoseconds: 2000000000)
            
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

// MARK: - Example WebSocket Delegate Implementation

/*
class ExampleWebSocketDelegate: WebSocketSessionManagerDelegate {
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
    }
    
    func webSocketSessionManager(_ manager: WebSocketSessionManager, shouldReauthenticateOnForeground user: Response.User) -> Bool {
        // Only re-authenticate if we have a current user and they match
        guard let currentUser = authService.getCurrentUser() else {
            AppLogger.shared.info("No current user, skipping WebSocket re-auth")
            return false
        }
        
        let shouldReauth = currentUser.username == user.username
        AppLogger.shared.info("Should re-authenticate WebSocket for \(user.username): \(shouldReauth)")
        return shouldReauth
    }
    
    func webSocketSessionManager(_ manager: WebSocketSessionManager, credentialsForReauthentication user: Response.User) -> (username: String, password: String, schoolCode: String)? {
        // This would typically access your credential storage (keychain, etc.)
        // and return the stored credentials for the user
        return nil // Implement based on your credential storage system
    }
    
    func webSocketSessionManager(_ manager: WebSocketSessionManager, didFailReauthenticationWithError error: Error) {
        AppLogger.shared.error("WebSocket re-authentication failed: \(error)")
        // Handle re-authentication failure - perhaps prompt user to log in again
    }
    
    func webSocketSessionManager(_ manager: WebSocketSessionManager, didSucceedReauthentication user: Response.User) {
        AppLogger.shared.info("WebSocket re-authentication succeeded for: \(user.username)")
        // Handle successful re-authentication if needed
    }
}
*/
