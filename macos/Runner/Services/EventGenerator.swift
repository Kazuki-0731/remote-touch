//
//  EventGenerator.swift
//  RemoteTouch macOS
//
//  Generates system events using CGEvent API for cursor movement, clicks, keyboard, and media controls
//

import Cocoa
import CoreGraphics
import ApplicationServices

/// Generates system events using CGEvent API
/// Requirements: 1.2, 2.2, 3.3, 3.4, 3.5, 3.6, 9.4, 9.5
class EventGenerator {
    
    // MARK: - Singleton
    static let shared = EventGenerator()
    
    private let accessibilityManager = AccessibilityManager.shared
    
    private init() {}
    
    // MARK: - Cursor Movement
    
    /// Moves the cursor by the specified delta
    /// - Parameter delta: The amount to move the cursor (x, y)
    /// 
    /// Requirements:
    /// - 1.2: Move cursor using CGEvent API when receiving swipe data
    /// - 10.3: Do not execute CGEvent API without accessibility permission
    func moveCursor(by delta: CGPoint) {
        // Requirement 10.3: Check accessibility permission before generating events
        guard accessibilityManager.canGenerateEvents() else {
            NSLog("EventGenerator: Cannot move cursor - no accessibility permission")
            NSLog("EventGenerator: Please grant accessibility permission in System Preferences")
            return
        }
        
        // Get current cursor position
        guard let currentLocation = NSEvent.mouseLocation as CGPoint? else {
            NSLog("EventGenerator: Failed to get current mouse location")
            return
        }
        
        // Validate delta values to prevent extreme movements
        // Requirement: Invalid command handling
        let maxDelta: CGFloat = 1000.0
        let clampedDelta = CGPoint(
            x: max(-maxDelta, min(maxDelta, delta.x)),
            y: max(-maxDelta, min(maxDelta, delta.y))
        )
        
        if clampedDelta != delta {
            NSLog("EventGenerator: Clamped cursor delta from (\(delta.x), \(delta.y)) to (\(clampedDelta.x), \(clampedDelta.y))")
        }
        
        // Calculate new position
        // Note: NSEvent.mouseLocation uses screen coordinates with origin at bottom-left
        // CGEvent uses the same coordinate system
        let newLocation = CGPoint(
            x: currentLocation.x + clampedDelta.x,
            y: currentLocation.y - clampedDelta.y  // Invert Y for natural touch direction
        )
        
        // Create and post mouse moved event
        // Requirement: Error handling for event generation failures
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: newLocation,
            mouseButton: .left
        ) {
            moveEvent.post(tap: .cghidEventTap)
        } else {
            NSLog("EventGenerator: Failed to create mouse move event")
            NSLog("EventGenerator: This may indicate a system-level issue")
        }
    }
    
    // MARK: - Click Events
    
    /// Generates a click event
    /// - Parameter type: The type of click (single or double)
    /// 
    /// Requirements:
    /// - 2.2: Generate left click and double click events using CGEvent API
    /// - 10.3: Do not execute CGEvent API without accessibility permission
    func generateClick(type: ClickType) {
        // Requirement 10.3: Check accessibility permission before generating events
        guard accessibilityManager.canGenerateEvents() else {
            NSLog("EventGenerator: Cannot generate click - no accessibility permission")
            NSLog("EventGenerator: Please grant accessibility permission in System Preferences")
            return
        }
        
        guard let currentLocation = NSEvent.mouseLocation as CGPoint? else {
            NSLog("EventGenerator: Failed to get current mouse location for click")
            return
        }
        
        switch type {
        case .single:
            postMouseClick(at: currentLocation, clickCount: 1)
        case .double:
            postMouseClick(at: currentLocation, clickCount: 2)
        }
    }
    
    /// Posts a mouse click event at the specified location
    /// - Parameters:
    ///   - location: The location to click
    ///   - clickCount: Number of clicks (1 for single, 2 for double)
    private func postMouseClick(at location: CGPoint, clickCount: Int) {
        // Create mouse down event
        if let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: location,
            mouseButton: .left
        ) {
            mouseDown.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
            mouseDown.post(tap: .cghidEventTap)
        }
        
        // Create mouse up event
        if let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: location,
            mouseButton: .left
        ) {
            mouseUp.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
            mouseUp.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - Keyboard Events
    
    /// Generates a keyboard event for the specified key
    /// - Parameters:
    ///   - keyCode: The virtual key code to press
    ///   - modifiers: Optional modifier flags (Command, Shift, etc.)
    /// 
    /// Requirements:
    /// - 3.3, 3.4, 3.5, 3.6: Generate keyboard events for arrow keys, Enter, Command combinations
    /// - 10.3: Do not execute CGEvent API without accessibility permission
    func generateKeyPress(_ keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        // Requirement 10.3: Check accessibility permission before generating events
        guard accessibilityManager.canGenerateEvents() else {
            NSLog("EventGenerator: Cannot generate key press - no accessibility permission")
            NSLog("EventGenerator: Please grant accessibility permission in System Preferences")
            return
        }
        
        // Create key down event
        // Requirement: Error handling for event generation failures
        if let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: true
        ) {
            keyDown.flags = modifiers
            keyDown.post(tap: .cghidEventTap)
        } else {
            NSLog("EventGenerator: Failed to create key down event for keyCode: \(keyCode)")
            return
        }
        
        // Small delay between key down and up for reliability
        usleep(10000) // 10ms
        
        // Create key up event
        if let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: false
        ) {
            keyUp.flags = modifiers
            keyUp.post(tap: .cghidEventTap)
        } else {
            NSLog("EventGenerator: Failed to create key up event for keyCode: \(keyCode)")
        }
    }
    
    /// Generates a key press for common navigation keys
    /// - Parameter key: The navigation key to press
    func generateNavigationKey(_ key: NavigationKey) {
        generateKeyPress(key.keyCode, modifiers: key.modifiers)
    }
    
    // MARK: - Media Control Events
    
    /// Generates a media control event
    /// - Parameter action: The media action to perform
    /// 
    /// Requirements:
    /// - 9.4, 9.5: Generate media key events for play/pause and volume control
    /// - 10.3: Do not execute CGEvent API without accessibility permission
    func generateMediaControl(_ action: MediaAction) {
        // Requirement 10.3: Check accessibility permission before generating events
        guard accessibilityManager.canGenerateEvents() else {
            NSLog("EventGenerator: Cannot generate media control - no accessibility permission")
            NSLog("EventGenerator: Please grant accessibility permission in System Preferences")
            return
        }
        
        let keyCode: Int32
        
        switch action {
        case .playPause:
            keyCode = NX_KEYTYPE_PLAY
        case .volumeUp:
            keyCode = NX_KEYTYPE_SOUND_UP
        case .volumeDown:
            keyCode = NX_KEYTYPE_SOUND_DOWN
        }
        
        // Create NSEvent for media keys and convert to CGEvent
        // Media keys use special system-defined events
        let flags: Int = 0xa00 // Media key flags
        
        // Key down
        let downData = NSEvent.EventSubtype(rawValue: Int(((keyCode << 16) | flags)))
        if let downEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: downData,
            data1: Int(keyCode << 16 | flags),
            data2: -1
        ) {
            downEvent.cgEvent?.post(tap: .cghidEventTap)
        }
        
        // Key up
        let upData = NSEvent.EventSubtype(rawValue: Int(((keyCode << 16) | (flags | 0xb00))))
        if let upEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: upData,
            data1: Int(keyCode << 16 | (flags | 0xb00)),
            data2: -1
        ) {
            upEvent.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}

// MARK: - Navigation Key Definitions

/// Common navigation keys with their key codes and modifiers
enum NavigationKey {
    case leftArrow
    case rightArrow
    case upArrow
    case downArrow
    case enter
    case escape
    case space
    case commandLeft
    case commandRight
    
    var keyCode: CGKeyCode {
        switch self {
        case .leftArrow:
            return 0x7B  // kVK_LeftArrow
        case .rightArrow:
            return 0x7C  // kVK_RightArrow
        case .upArrow:
            return 0x7E  // kVK_UpArrow
        case .downArrow:
            return 0x7D  // kVK_DownArrow
        case .enter:
            return 0x24  // kVK_Return
        case .escape:
            return 0x35  // kVK_Escape
        case .space:
            return 0x31  // kVK_Space
        case .commandLeft:
            return 0x7B  // kVK_LeftArrow with Command
        case .commandRight:
            return 0x7C  // kVK_RightArrow with Command
        }
    }
    
    var modifiers: CGEventFlags {
        switch self {
        case .commandLeft, .commandRight:
            return .maskCommand
        default:
            return []
        }
    }
}

// MARK: - Media Key Constants

/// Media key type constants from IOKit
private let NX_KEYTYPE_PLAY: Int32 = 16
private let NX_KEYTYPE_SOUND_UP: Int32 = 0
private let NX_KEYTYPE_SOUND_DOWN: Int32 = 1
private let NX_SUBTYPE_AUX_CONTROL_BUTTONS: Int32 = 8
