//
//  CommandProcessorIntegrationExample.swift
//  RemoteTouch macOS
//
//  Example demonstrating CommandProcessor integration with BLE
//

import Foundation
import CoreGraphics

/// Example demonstrating how CommandProcessor integrates with the BLE system
class CommandProcessorIntegrationExample {
    
    // MARK: - Example 1: Basic Command Flow
    
    /// Demonstrates the complete flow from BLE to system event
    static func exampleBasicCommandFlow() {
        print("=== Example 1: Basic Command Flow ===\n")
        
        // 1. iOS app sends cursor move command via BLE
        let cursorCommand = CursorMoveCommand(delta: CGPoint(x: 10, y: 20))
        print("iOS → BLE: CursorMoveCommand(delta: (10, 20))")
        
        // 2. BLEPeripheralManager receives and parses the command
        print("BLEPeripheralManager: Command received and parsed")
        
        // 3. ApplicationController (as delegate) receives the command
        print("ApplicationController: Routing command to CommandProcessor")
        
        // 4. CommandProcessor processes the command
        let processor = CommandProcessor()
        processor.processCommand(cursorCommand)
        print("CommandProcessor: Processing cursor move")
        
        // 5. EventGenerator creates system event
        print("EventGenerator: Moving cursor by (10, 20)")
        print("macOS System: Cursor moved\n")
    }
    
    // MARK: - Example 2: Mode-Specific Button Actions
    
    /// Demonstrates how button actions change based on control mode
    static func exampleModeSpecificButtons() {
        print("=== Example 2: Mode-Specific Button Actions ===\n")
        
        let processor = CommandProcessor()
        let backButton = ButtonCommand(action: .back)
        
        // Presentation Mode
        print("Mode: Presentation")
        processor.setMode(.presentation)
        processor.processCommand(backButton)
        print("Back button → Left arrow key (previous slide)\n")
        
        // Basic Mouse Mode
        print("Mode: Basic Mouse")
        processor.setMode(.basicMouse)
        processor.processCommand(backButton)
        print("Back button → Command+Left arrow (browser back)\n")
        
        // Media Control Mode
        print("Mode: Media Control")
        processor.setMode(.mediaControl)
        processor.processCommand(backButton)
        print("Back button → Left arrow (previous track)\n")
    }
    
    // MARK: - Example 3: Media Control Mode
    
    /// Demonstrates media control functionality
    static func exampleMediaControl() {
        print("=== Example 3: Media Control Mode ===\n")
        
        let processor = CommandProcessor()
        processor.setMode(.mediaControl)
        
        // Single tap for play/pause
        print("User taps touchpad")
        let tapCommand = TapCommand(clickType: .single)
        processor.processCommand(tapCommand)
        print("Result: Play/Pause media\n")
        
        // Swipe up for volume up
        print("User swipes up")
        let volumeUpCommand = MediaControlCommand(action: .volumeUp)
        processor.processCommand(volumeUpCommand)
        print("Result: Volume increased\n")
        
        // Swipe down for volume down
        print("User swipes down")
        let volumeDownCommand = MediaControlCommand(action: .volumeDown)
        processor.processCommand(volumeDownCommand)
        print("Result: Volume decreased\n")
    }
    
    // MARK: - Example 4: Complete User Scenario
    
    /// Demonstrates a complete user scenario
    static func exampleCompleteScenario() {
        print("=== Example 4: Complete User Scenario ===\n")
        
        let processor = CommandProcessor()
        
        // User starts in basic mouse mode
        print("1. User opens RemoteTouch app")
        processor.setMode(.basicMouse)
        print("   Mode: Basic Mouse\n")
        
        // User moves cursor
        print("2. User swipes on touchpad")
        let moveCommand = CursorMoveCommand(delta: CGPoint(x: 50, y: -30))
        processor.processCommand(moveCommand)
        print("   Cursor moved by (50, -30)\n")
        
        // User clicks
        print("3. User taps touchpad")
        let clickCommand = TapCommand(clickType: .single)
        processor.processCommand(clickCommand)
        print("   Left click generated\n")
        
        // User switches to presentation mode
        print("4. User switches to Presentation mode")
        let modeCommand = ModeChangeCommand(mode: .presentation)
        processor.processCommand(modeCommand)
        print("   Mode: Presentation\n")
        
        // User navigates slides
        print("5. User presses forward button")
        let forwardCommand = ButtonCommand(action: .forward)
        processor.processCommand(forwardCommand)
        print("   Right arrow key → Next slide\n")
        
        print("6. User presses back button")
        let backCommand = ButtonCommand(action: .back)
        processor.processCommand(backCommand)
        print("   Left arrow key → Previous slide\n")
        
        // User switches to media control
        print("7. User switches to Media Control mode")
        let mediaMode = ModeChangeCommand(mode: .mediaControl)
        processor.processCommand(mediaMode)
        print("   Mode: Media Control\n")
        
        // User controls media
        print("8. User taps to play/pause")
        processor.processCommand(clickCommand)
        print("   Media play/pause toggled\n")
    }
    
    // MARK: - Example 5: Error Handling
    
    /// Demonstrates error handling scenarios
    static func exampleErrorHandling() {
        print("=== Example 5: Error Handling ===\n")
        
        let processor = CommandProcessor()
        
        // Unknown command type
        print("Scenario 1: Unknown command type")
        let unknownCommand = "invalid command"
        processor.processCommand(unknownCommand)
        print("Result: Command ignored, logged as unknown\n")
        
        // Pinch command (not yet implemented)
        print("Scenario 2: Pinch command (future feature)")
        let pinchCommand = PinchCommand(scale: 1.5)
        processor.processCommand(pinchCommand)
        print("Result: Logged as not implemented\n")
    }
    
    // MARK: - Run All Examples
    
    /// Run all examples
    static func runAllExamples() {
        exampleBasicCommandFlow()
        print("\n" + String(repeating: "-", count: 50) + "\n")
        
        exampleModeSpecificButtons()
        print("\n" + String(repeating: "-", count: 50) + "\n")
        
        exampleMediaControl()
        print("\n" + String(repeating: "-", count: 50) + "\n")
        
        exampleCompleteScenario()
        print("\n" + String(repeating: "-", count: 50) + "\n")
        
        exampleErrorHandling()
    }
}

// MARK: - Usage
// Uncomment to run examples:
// CommandProcessorIntegrationExample.runAllExamples()
