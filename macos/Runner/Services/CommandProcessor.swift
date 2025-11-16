//
//  CommandProcessor.swift
//  RemoteTouch macOS
//
//  Processes commands received from iOS and dispatches to EventGenerator
//  Requirements: 3.3, 3.4, 3.5, 3.6, 7.5, 9.4, 9.5
//

import Foundation
import CoreGraphics

/// Processes commands received from iOS device and generates appropriate system events
class CommandProcessor {
    
    // MARK: - Properties
    
    /// Current control mode
    private(set) var currentMode: ControlMode = .basicMouse
    
    /// Event generator for system events
    private let eventGenerator: EventGenerator
    
    // MARK: - Initialization
    
    init(eventGenerator: EventGenerator = .shared) {
        self.eventGenerator = eventGenerator
    }
    
    // MARK: - Public Methods
    
    /// Process a received command
    /// - Parameter command: The command to process (can be any command type)
    /// 
    /// Requirements:
    /// - 4.5: Handle invalid commands gracefully without crashing
    func processCommand(_ command: Any) {
        // Requirement 4.5: Validate command before processing
        guard validateCommand(command) else {
            NSLog("CommandProcessor: Invalid command received - ignoring")
            return
        }
        
        switch command {
        case let cmd as CursorMoveCommand:
            handleCursorMove(cmd)
        case let cmd as TapCommand:
            handleTap(cmd)
        case let cmd as ButtonCommand:
            handleButton(cmd)
        case let cmd as ModeChangeCommand:
            handleModeChange(cmd)
        case let cmd as MediaControlCommand:
            handleMediaControl(cmd)
        case let cmd as PinchCommand:
            handlePinch(cmd)
        default:
            // Requirement 4.5: Log unknown command types for debugging
            NSLog("CommandProcessor: Unknown command type received: \(type(of: command))")
            NSLog("CommandProcessor: Command will be ignored to prevent errors")
        }
    }
    
    /// Validate a command before processing
    /// - Parameter command: The command to validate
    /// - Returns: true if command is valid, false otherwise
    /// 
    /// Requirement 4.5: Invalid command validation
    private func validateCommand(_ command: Any) -> Bool {
        // Check for nil or invalid command objects
        if command is NSNull {
            NSLog("CommandProcessor: Received null command")
            return false
        }
        
        // Validate cursor move commands
        if let cmd = command as? CursorMoveCommand {
            // Check for reasonable delta values (prevent extreme movements)
            let maxDelta: CGFloat = 10000.0
            if abs(cmd.delta.x) > maxDelta || abs(cmd.delta.y) > maxDelta {
                NSLog("CommandProcessor: Cursor delta too large: (\(cmd.delta.x), \(cmd.delta.y))")
                return false
            }
        }
        
        // Validate pinch commands
        if let cmd = command as? PinchCommand {
            // Check for reasonable scale values
            if cmd.scale <= 0 || cmd.scale > 10.0 {
                NSLog("CommandProcessor: Invalid pinch scale: \(cmd.scale)")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Command Handlers
    
    /// Handle cursor movement command
    /// - Parameter command: The cursor move command
    /// - Requirement: 1.2 - Move cursor using CGEvent API
    private func handleCursorMove(_ command: CursorMoveCommand) {
        let delta = command.delta.cgPoint
        eventGenerator.moveCursor(by: delta)
        NSLog("CommandProcessor: Moved cursor by (\(delta.x), \(delta.y))")
    }
    
    /// Handle tap command
    /// - Parameter command: The tap command
    /// - Requirement: 2.2 - Generate click events based on tap type
    private func handleTap(_ command: TapCommand) {
        // In media control mode, single tap is play/pause
        if currentMode == .mediaControl && command.clickType == .single {
            eventGenerator.generateMediaControl(.playPause)
            NSLog("CommandProcessor: Media control - play/pause")
        } else {
            // Normal click behavior for other modes
            eventGenerator.generateClick(type: command.clickType)
            NSLog("CommandProcessor: Generated \(command.clickType) click")
        }
    }
    
    /// Handle button command (back/forward buttons)
    /// - Parameter command: The button command
    /// - Requirements: 3.3, 3.4, 3.5, 3.6 - Mode-specific button actions
    private func handleButton(_ command: ButtonCommand) {
        switch (command.action, currentMode) {
        // Presentation mode
        case (.back, .presentation):
            // Requirement 3.3: Left arrow for back in presentation mode
            eventGenerator.generateNavigationKey(.leftArrow)
            NSLog("CommandProcessor: Presentation mode - back (left arrow)")
            
        case (.forward, .presentation):
            // Requirement 3.4: Right arrow for forward in presentation mode
            eventGenerator.generateNavigationKey(.rightArrow)
            NSLog("CommandProcessor: Presentation mode - forward (right arrow)")
            
        // Basic mouse mode
        case (.back, .basicMouse):
            // Requirement 3.5: Command+Left arrow for back in basic mouse mode
            eventGenerator.generateNavigationKey(.commandLeft)
            NSLog("CommandProcessor: Basic mouse mode - back (Command+left arrow)")
            
        case (.forward, .basicMouse):
            // Requirement 3.6: Enter key for forward in basic mouse mode
            eventGenerator.generateNavigationKey(.enter)
            NSLog("CommandProcessor: Basic mouse mode - forward (Enter)")
            
        // Media control mode
        case (.back, .mediaControl):
            // Previous track or rewind
            eventGenerator.generateNavigationKey(.leftArrow)
            NSLog("CommandProcessor: Media control mode - back (left arrow)")
            
        case (.forward, .mediaControl):
            // Next track or fast forward
            eventGenerator.generateNavigationKey(.rightArrow)
            NSLog("CommandProcessor: Media control mode - forward (right arrow)")
        }
    }
    
    /// Handle mode change command
    /// - Parameter command: The mode change command
    /// - Requirement: 7.5 - Update mode based on received command
    private func handleModeChange(_ command: ModeChangeCommand) {
        let previousMode = currentMode
        currentMode = command.mode
        NSLog("CommandProcessor: Mode changed from \(previousMode) to \(currentMode)")
    }
    
    /// Handle media control command
    /// - Parameter command: The media control command
    /// - Requirements: 9.4, 9.5 - Generate media key events
    private func handleMediaControl(_ command: MediaControlCommand) {
        eventGenerator.generateMediaControl(command.action)
        NSLog("CommandProcessor: Media control - \(command.action)")
    }
    
    /// Handle pinch command
    /// - Parameter command: The pinch command
    private func handlePinch(_ command: PinchCommand) {
        // Pinch gestures could be used for zoom or other actions
        // For now, we'll log it as not implemented
        NSLog("CommandProcessor: Pinch gesture received (scale: \(command.scale)) - not implemented")
    }
    
    // MARK: - Public Accessors
    
    /// Get the current control mode
    var mode: ControlMode {
        return currentMode
    }
    
    /// Set the control mode directly (for testing or initialization)
    func setMode(_ mode: ControlMode) {
        currentMode = mode
        NSLog("CommandProcessor: Mode set to \(mode)")
    }
}
