//
//  StatusData.swift
//  RemoteTouch macOS
//
//  Status data sent from macOS to iOS
//

import Foundation

/// Status data sent from macOS to iOS
struct StatusData: Codable {
    let batteryLevel: Int
    let timestamp: Date
    let connectionQuality: Int
    
    init(batteryLevel: Int, timestamp: Date = Date(), connectionQuality: Int) {
        self.batteryLevel = batteryLevel
        self.timestamp = timestamp
        self.connectionQuality = connectionQuality
    }
    
    enum CodingKeys: String, CodingKey {
        case batteryLevel
        case timestamp
        case connectionQuality
    }
    
    /// Encode to JSON data
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
    
    /// Decode from JSON data
    static func fromJSON(_ data: Data) throws -> StatusData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StatusData.self, from: data)
    }
    
    /// Encode date as ISO8601 string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(connectionQuality, forKey: .connectionQuality)
        
        let formatter = ISO8601DateFormatter()
        let timestampString = formatter.string(from: timestamp)
        try container.encode(timestampString, forKey: .timestamp)
    }
    
    /// Decode date from ISO8601 string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        batteryLevel = try container.decode(Int.self, forKey: .batteryLevel)
        connectionQuality = try container.decode(Int.self, forKey: .connectionQuality)
        
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestampString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .timestamp,
                in: container,
                debugDescription: "Invalid ISO8601 date string"
            )
        }
        timestamp = date
    }
}

// MARK: - CustomStringConvertible

extension StatusData: CustomStringConvertible {
    var description: String {
        return "StatusData(batteryLevel: \(batteryLevel), timestamp: \(timestamp), connectionQuality: \(connectionQuality))"
    }
}
