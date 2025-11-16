//
//  AppSettings.swift
//  RemoteTouch macOS
//
//  Application settings for macOS app
//

import Foundation

/// Application settings
struct AppSettings: Codable {
    let sensitivity: Double
    let idleTimeout: TimeInterval
    let autoReconnect: Bool
    let maxReconnectAttempts: Int
    
    init(
        sensitivity: Double = 1.0,
        idleTimeout: TimeInterval = 60.0,
        autoReconnect: Bool = true,
        maxReconnectAttempts: Int = 10
    ) {
        self.sensitivity = sensitivity
        self.idleTimeout = idleTimeout
        self.autoReconnect = autoReconnect
        self.maxReconnectAttempts = maxReconnectAttempts
    }
    
    enum CodingKeys: String, CodingKey {
        case sensitivity
        case idleTimeout
        case autoReconnect
        case maxReconnectAttempts
    }
    
    /// Encode to JSON data
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    /// Decode from JSON data
    static func fromJSON(_ data: Data) throws -> AppSettings {
        let decoder = JSONDecoder()
        return try decoder.decode(AppSettings.self, from: data)
    }
    
    /// Create a copy with modified properties
    func copyWith(
        sensitivity: Double? = nil,
        idleTimeout: TimeInterval? = nil,
        autoReconnect: Bool? = nil,
        maxReconnectAttempts: Int? = nil
    ) -> AppSettings {
        return AppSettings(
            sensitivity: sensitivity ?? self.sensitivity,
            idleTimeout: idleTimeout ?? self.idleTimeout,
            autoReconnect: autoReconnect ?? self.autoReconnect,
            maxReconnectAttempts: maxReconnectAttempts ?? self.maxReconnectAttempts
        )
    }
}

// MARK: - CustomStringConvertible

extension AppSettings: CustomStringConvertible {
    var description: String {
        return "AppSettings(sensitivity: \(sensitivity), idleTimeout: \(idleTimeout), autoReconnect: \(autoReconnect), maxReconnectAttempts: \(maxReconnectAttempts))"
    }
}

// MARK: - Equatable

extension AppSettings: Equatable {
    static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        return lhs.sensitivity == rhs.sensitivity &&
               lhs.idleTimeout == rhs.idleTimeout &&
               lhs.autoReconnect == rhs.autoReconnect &&
               lhs.maxReconnectAttempts == rhs.maxReconnectAttempts
    }
}

// MARK: - Hashable

extension AppSettings: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(sensitivity)
        hasher.combine(idleTimeout)
        hasher.combine(autoReconnect)
        hasher.combine(maxReconnectAttempts)
    }
}
