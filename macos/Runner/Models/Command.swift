//
//  Command.swift
//  RemoteTouch macOS
//
//  Data models for commands sent from iOS to macOS
//

import Foundation
import CoreGraphics

// MARK: - Command Types

/// Types of click actions
enum ClickType: String, Codable {
    case single
    case double
}

/// Button actions
enum ButtonAction: String, Codable {
    case back
    case forward
}

/// Control modes for the app
enum ControlMode: String, Codable {
    case presentation
    case mediaControl
    case basicMouse
}

/// Media control actions
enum MediaAction: String, Codable {
    case playPause
    case volumeUp
    case volumeDown
}

// MARK: - Command Protocol

/// Base protocol for all commands
protocol CommandProtocol: Codable {
    var type: String { get }
}

// MARK: - Command Implementations

/// Command for cursor movement
struct CursorMoveCommand: CommandProtocol, Codable {
    let type: String = "cursorMove"
    let delta: CGPointCodable
    
    init(delta: CGPoint) {
        self.delta = CGPointCodable(point: delta)
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case delta
    }
}

/// Command for tap actions
struct TapCommand: CommandProtocol, Codable {
    let type: String = "tap"
    let clickType: ClickType
    
    enum CodingKeys: String, CodingKey {
        case type
        case clickType
    }
}

/// Command for button actions
struct ButtonCommand: CommandProtocol, Codable {
    let type: String = "button"
    let action: ButtonAction
    
    enum CodingKeys: String, CodingKey {
        case type
        case action
    }
}

/// Command for mode changes
struct ModeChangeCommand: CommandProtocol, Codable {
    let type: String = "modeChange"
    let mode: ControlMode
    
    enum CodingKeys: String, CodingKey {
        case type
        case mode
    }
}

/// Command for media control
struct MediaControlCommand: CommandProtocol, Codable {
    let type: String = "mediaControl"
    let action: MediaAction
    
    enum CodingKeys: String, CodingKey {
        case type
        case action
    }
}

/// Command for pinch gestures
struct PinchCommand: CommandProtocol, Codable {
    let type: String = "pinch"
    let scale: Double
    
    enum CodingKeys: String, CodingKey {
        case type
        case scale
    }
}

// MARK: - Command Parser

/// Parser for incoming command JSON
struct CommandParser {
    /// Parse JSON data into a specific command type
    static func parse(_ data: Data) throws -> Any {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let type = json?["type"] as? String else {
            throw CommandError.invalidFormat
        }
        
        let decoder = JSONDecoder()
        
        switch type {
        case "cursorMove":
            return try decoder.decode(CursorMoveCommand.self, from: data)
        case "tap":
            return try decoder.decode(TapCommand.self, from: data)
        case "button":
            return try decoder.decode(ButtonCommand.self, from: data)
        case "modeChange":
            return try decoder.decode(ModeChangeCommand.self, from: data)
        case "mediaControl":
            return try decoder.decode(MediaControlCommand.self, from: data)
        case "pinch":
            return try decoder.decode(PinchCommand.self, from: data)
        default:
            throw CommandError.unknownType(type)
        }
    }
}

// MARK: - Helper Types

/// Codable wrapper for CGPoint
struct CGPointCodable: Codable {
    let dx: Double
    let dy: Double
    
    init(point: CGPoint) {
        self.dx = Double(point.x)
        self.dy = Double(point.y)
    }
    
    var cgPoint: CGPoint {
        return CGPoint(x: dx, y: dy)
    }
    
    enum CodingKeys: String, CodingKey {
        case dx
        case dy
    }
}

// MARK: - Errors

enum CommandError: Error {
    case invalidFormat
    case unknownType(String)
    case decodingFailed(Error)
}
