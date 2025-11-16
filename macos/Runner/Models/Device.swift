//
//  Device.swift
//  RemoteTouch macOS
//
//  Represents a paired iOS device
//

import Foundation

/// Represents an iOS device that can be connected to
struct Device: Codable, Identifiable {
    let id: String
    let name: String
    let peripheralUUID: String
    let lastConnected: Date
    let isPaired: Bool
    
    init(id: String, name: String, peripheralUUID: String, lastConnected: Date, isPaired: Bool) {
        self.id = id
        self.name = name
        self.peripheralUUID = peripheralUUID
        self.lastConnected = lastConnected
        self.isPaired = isPaired
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case peripheralUUID
        case lastConnected
        case isPaired
    }
    
    /// Encode to JSON data
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
    
    /// Decode from JSON data
    static func fromJSON(_ data: Data) throws -> Device {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Device.self, from: data)
    }
    
    /// Encode date as ISO8601 string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(peripheralUUID, forKey: .peripheralUUID)
        try container.encode(isPaired, forKey: .isPaired)
        
        let formatter = ISO8601DateFormatter()
        let timestampString = formatter.string(from: lastConnected)
        try container.encode(timestampString, forKey: .lastConnected)
    }
    
    /// Decode date from ISO8601 string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        peripheralUUID = try container.decode(String.self, forKey: .peripheralUUID)
        isPaired = try container.decode(Bool.self, forKey: .isPaired)
        
        let timestampString = try container.decode(String.self, forKey: .lastConnected)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestampString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .lastConnected,
                in: container,
                debugDescription: "Invalid ISO8601 date string"
            )
        }
        lastConnected = date
    }
    
    /// Create a copy with modified properties
    func copyWith(
        id: String? = nil,
        name: String? = nil,
        peripheralUUID: String? = nil,
        lastConnected: Date? = nil,
        isPaired: Bool? = nil
    ) -> Device {
        return Device(
            id: id ?? self.id,
            name: name ?? self.name,
            peripheralUUID: peripheralUUID ?? self.peripheralUUID,
            lastConnected: lastConnected ?? self.lastConnected,
            isPaired: isPaired ?? self.isPaired
        )
    }
}

// MARK: - CustomStringConvertible

extension Device: CustomStringConvertible {
    var description: String {
        return "Device(id: \(id), name: \(name), peripheralUUID: \(peripheralUUID), lastConnected: \(lastConnected), isPaired: \(isPaired))"
    }
}

// MARK: - Equatable

extension Device: Equatable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.peripheralUUID == rhs.peripheralUUID &&
               lhs.lastConnected == rhs.lastConnected &&
               lhs.isPaired == rhs.isPaired
    }
}

// MARK: - Hashable

extension Device: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(peripheralUUID)
        hasher.combine(lastConnected)
        hasher.combine(isPaired)
    }
}
