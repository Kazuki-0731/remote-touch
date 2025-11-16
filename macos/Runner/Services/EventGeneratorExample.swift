//
//  EventGeneratorExample.swift
//  RemoteTouch macOS
//
//  Example usage of EventGenerator with different command types
//  This demonstrates how EventGenerator will be integrated with CommandProcessor (Task 16)
//

import Foundation
import CoreGraphics

/// Example class showing how to use EventGenerator with commands
class EventGeneratorExample {
    
    private let eventGenerator = EventGenerator.shared
    
    // MARK: - Cursor Movement Examples
    
    /// Example: Handle cursor move command from iOS
    /// - Requirement: 1.2 - Move cursor when receiving swipe data
    func handleCursorMoveCommand(_ command: CursorMoveCommand) {
        let delta = command.delta.cgPoint
        eventGenerator.moveCursor(by: delta)
        NSLog("EventGenerator: Moved cursor by (\(delta.x), \(delta.y))")
    }
    
    // MARK: - Click Examples
    
    /// Example: Handle tap command from iOS
    /// - Requirement: 2.2 - Generate click events
    func handleTapCommand(_ command: TapCommand) {
        eventGenerator.generateClick(type: command.clickType)
        NSLog("EventGenerator: Generated \(command.clickType) click")
    }
    
    // MARK: - Button Action Examples
    
    /// Example: Handle button command in presentation mode
    /// - Requirement: 3.3, 3.4 - Generate arrow key events for presentation mode
    func handleButtonCommandInPresentationMode(_ command: ButtonCommand) {
        switch command.action {
        case .back:
            eventGenerator.generateNavigationKey(.leftArrow)
            NSLog("EventGenerator: Presentation mode - Previous slide")
        case .forward:
            eventGenerator.generateNavigationKey(.rightArrow)
            NSLog("EventGenerator: Presentation mode - Next slide")
        }
    }
    
    /// Example: Handle button command in basic mouse mode
    /// - Requirement: 3.5, 3.6 - Generate Command+Arrow and Enter key events
    func handleButtonCommandInBasicMouseMode(_ command: ButtonCommand) {
        switch command.action {
        case .back:
            eventGenerator.generateNavigationKey(.commandLeft)
            NSLog("EventGenerator: Basic mouse mode - Back (Command+Left)")
        case .forward:
            eventGenerator.generateNavigationKey(.enter)
            NSLog("EventGenerator: Basic mouse mode - Enter")
        }
    }
    
    // MARK: - Media Control Examples
    
    /// Example: Handle media control command
    /// - Requirement: 9.4, 9.5 - Generate media key events
    func handleMediaControlCommand(_ command: MediaControlCommand) {
        eventGenerator.generateMediaControl(command.action)
        
        let actionName: String
        switch command.action {
        case .playPause:
            actionName = "Play/Pause"
        case .volumeUp:
            actionName = "Volume Up"
        case .volumeDown:
            actionName = "Volume Down"
        }
        
        NSLog("EventGenerator: Media control - \(actionName)")
    }
    
    // MARK: - Complete Command Processing Example
    
    /// Example: Process any command based on current mode
    /// This demonstrates the pattern that CommandProcessor (Task 16) will implement
    func processCommand(_ commandData: Data, currentMode: ControlMode) {
        do {
            let command = try CommandParser.parse(commandData)
            
            switch command {
            case let cmd as CursorMoveCommand:
                handleCursorMoveCommand(cmd)
                
            case let cmd as TapCommand:
                handleTapCommand(cmd)
                
            case let cmd as ButtonCommand:
                // Handle based on current mode
                switch currentMode {
                case .presentation:
                    handleButtonCommandInPresentationMode(cmd)
                case .basicMouse:
                    handleButtonCommandInBasicMouseMode(cmd)
                case .mediaControl:
                    // In media mode, buttons might have different meanings
                    handleButtonCommandInPresentationMode(cmd)
                }
                
            case let cmd as MediaControlCommand:
                handleMediaControlCommand(cmd)
                
            case let cmd as ModeChangeCommand:
                NSLog("EventGenerator: Mode changed to \(cmd.mode)")
                // Mode change would be handled by CommandProcessor
                
            default:
                NSLog("EventGenerator: Unknown command type")
            }
            
        } catch {
            NSLog("EventGenerator: Failed to parse command - \(error)")
        }
    }
}

// MARK: - Usage Examples

extension EventGeneratorExample {
    
    /// Example: Simulate receiving commands from iOS app
    static func demonstrateUsage() {
        let example = EventGeneratorExample()
        
        // Example 1: Cursor movement
        let cursorMove = CursorMoveCommand(delta: CGPoint(x: 10, y: -5))
        if let data = try? JSONEncoder().encode(cursorMove) {
            example.processCommand(data, currentMode: .basicMouse)
        }
        
        // Example 2: Single click
        let tap = TapCommand(clickType: .single)
        if let data = try? JSONEncoder().encode(tap) {
            example.processCommand(data, currentMode: .basicMouse)
        }
        
        // Example 3: Presentation mode navigation
        let backButton = ButtonCommand(action: .back)
        if let data = try? JSONEncoder().encode(backButton) {
            example.processCommand(data, currentMode: .presentation)
        }
        
        // Example 4: Media control
        let mediaControl = MediaControlCommand(action: .playPause)
        if let data = try? JSONEncoder().encode(mediaControl) {
            example.processCommand(data, currentMode: .mediaControl)
        }
    }
}
