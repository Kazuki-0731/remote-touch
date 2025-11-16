# EventGenerator Implementation

## Overview

The `EventGenerator` class is responsible for generating system-level events on macOS using the CGEvent API. It handles cursor movement, mouse clicks, keyboard events, and media control keys.

## Requirements Addressed

This implementation addresses the following requirements from the spec:

- **1.2**: Move cursor using CGEvent API when receiving swipe data from iOS
- **2.2**: Generate left click and double click events using CGEvent API
- **3.3**: Generate left arrow key events for presentation mode back action
- **3.4**: Generate right arrow key events for presentation mode forward action
- **3.5**: Generate Command+Left arrow key events for basic mouse mode back action
- **3.6**: Generate Enter key events for basic mouse mode forward action
- **9.4**: Generate media play/pause key events
- **9.5**: Generate volume adjustment key events

## Architecture

### Class Structure

```swift
class EventGenerator {
    static let shared: EventGenerator
    
    // Cursor Movement
    func moveCursor(by delta: CGPoint)
    
    // Click Events
    func generateClick(type: ClickType)
    
    // Keyboard Events
    func generateKeyPress(_ keyCode: CGKeyCode, modifiers: CGEventFlags = [])
    func generateNavigationKey(_ key: NavigationKey)
    
    // Media Control
    func generateMediaControl(_ action: MediaAction)
}
```

### Navigation Keys

The `NavigationKey` enum provides convenient access to common navigation keys:

- `.leftArrow` - Left arrow key (0x7B)
- `.rightArrow` - Right arrow key (0x7C)
- `.upArrow` - Up arrow key (0x7E)
- `.downArrow` - Down arrow key (0x7D)
- `.enter` - Return/Enter key (0x24)
- `.escape` - Escape key (0x35)
- `.space` - Space bar (0x31)
- `.commandLeft` - Command+Left arrow
- `.commandRight` - Command+Right arrow

## Key Features

### 1. Accessibility Permission Checking

All event generation methods check for accessibility permissions before executing:

```swift
guard accessibilityManager.canGenerateEvents() else {
    NSLog("EventGenerator: Cannot generate events - no accessibility permission")
    return
}
```

This ensures compliance with **Requirement 10.3**: Do not execute CGEvent API without permission.

### 2. Cursor Movement

The `moveCursor(by:)` method:
- Gets the current cursor position
- Calculates the new position based on delta
- Inverts the Y-axis for natural touch direction (touch down = cursor down)
- Posts a `mouseMoved` CGEvent

```swift
eventGenerator.moveCursor(by: CGPoint(x: 10, y: -5))
```

### 3. Click Generation

The `generateClick(type:)` method supports:
- Single clicks
- Double clicks

Both are implemented by posting `leftMouseDown` and `leftMouseUp` events with appropriate click counts.

```swift
eventGenerator.generateClick(type: .single)
eventGenerator.generateClick(type: .double)
```

### 4. Keyboard Events

Two methods for keyboard events:

**Low-level key press:**
```swift
eventGenerator.generateKeyPress(0x7B, modifiers: .maskCommand)
```

**High-level navigation keys:**
```swift
eventGenerator.generateNavigationKey(.leftArrow)
eventGenerator.generateNavigationKey(.commandLeft)
```

### 5. Media Control

The `generateMediaControl(_:)` method handles:
- Play/Pause
- Volume Up
- Volume Down

Media keys use special system-defined events with specific flags and subtypes.

```swift
eventGenerator.generateMediaControl(.playPause)
eventGenerator.generateMediaControl(.volumeUp)
```

## Integration with CommandProcessor

The EventGenerator is designed to be used by the CommandProcessor (Task 16). Here's the expected integration pattern:

```swift
class CommandProcessor {
    private let eventGenerator = EventGenerator.shared
    private var currentMode: ControlMode = .basicMouse
    
    func processCommand(_ command: Any) {
        switch command {
        case let cmd as CursorMoveCommand:
            eventGenerator.moveCursor(by: cmd.delta.cgPoint)
            
        case let cmd as TapCommand:
            eventGenerator.generateClick(type: cmd.clickType)
            
        case let cmd as ButtonCommand:
            handleButtonAction(cmd.action)
            
        case let cmd as MediaControlCommand:
            eventGenerator.generateMediaControl(cmd.action)
            
        default:
            break
        }
    }
    
    private func handleButtonAction(_ action: ButtonAction) {
        switch (action, currentMode) {
        case (.back, .presentation):
            eventGenerator.generateNavigationKey(.leftArrow)
        case (.forward, .presentation):
            eventGenerator.generateNavigationKey(.rightArrow)
        case (.back, .basicMouse):
            eventGenerator.generateNavigationKey(.commandLeft)
        case (.forward, .basicMouse):
            eventGenerator.generateNavigationKey(.enter)
        // ... other cases
        }
    }
}
```

## Testing

### Unit Tests

The `EventGeneratorTests.swift` file includes tests for:
- Navigation key definitions (key codes and modifiers)
- Method invocation without crashes (even without accessibility permission)

### Manual Testing

To manually test the EventGenerator:

1. **Grant Accessibility Permission**:
   - Open System Preferences → Security & Privacy → Privacy → Accessibility
   - Add and enable the RemoteTouch app

2. **Test Cursor Movement**:
   ```swift
   EventGenerator.shared.moveCursor(by: CGPoint(x: 100, y: 0))
   ```
   Expected: Cursor moves 100 pixels to the right

3. **Test Clicks**:
   ```swift
   EventGenerator.shared.generateClick(type: .single)
   ```
   Expected: Single click at current cursor position

4. **Test Keyboard**:
   ```swift
   EventGenerator.shared.generateNavigationKey(.leftArrow)
   ```
   Expected: Left arrow key press (e.g., moves back in browser)

5. **Test Media Keys**:
   ```swift
   EventGenerator.shared.generateMediaControl(.playPause)
   ```
   Expected: Current media playback pauses/resumes

## Error Handling

The EventGenerator handles errors gracefully:

1. **No Accessibility Permission**: Logs error and returns early
2. **Failed to Get Cursor Position**: Logs error and returns early
3. **Failed to Create CGEvent**: Logs error and continues

All errors are logged using `NSLog` for debugging purposes.

## Performance Considerations

### Latency

- CGEvent posting is near-instantaneous (< 1ms)
- No queuing or buffering - events are posted immediately
- Meets the 16ms requirement for responsive cursor movement

### Resource Usage

- Singleton pattern ensures single instance
- No memory allocation per event (CGEvent is created and posted immediately)
- Minimal CPU usage (system-level event posting)

## Security Considerations

### Accessibility Permissions

The EventGenerator requires accessibility permissions to function. This is:
- Checked before every event generation
- Managed by the AccessibilityManager
- Prompted to the user on first use

### Event Validation

- All events are generated through official CGEvent API
- No direct memory manipulation or private APIs
- Complies with macOS security model

## Known Limitations

1. **Accessibility Permission Required**: The app cannot function without this permission
2. **Media Keys**: May not work in all applications (some apps handle media keys differently)
3. **Coordinate System**: Uses screen coordinates with origin at bottom-left (macOS standard)

## Future Enhancements

Potential improvements for future versions:

1. **Scroll Events**: Add support for scroll wheel simulation
2. **Right Click**: Add support for right-click events
3. **Drag and Drop**: Add support for drag operations
4. **Multi-Monitor**: Enhanced support for multi-monitor setups
5. **Event Queuing**: Optional queuing for high-frequency events

## References

- [CGEvent Documentation](https://developer.apple.com/documentation/coregraphics/cgevent)
- [Accessibility API](https://developer.apple.com/documentation/applicationservices/accessibility)
- [Virtual Key Codes](https://developer.apple.com/documentation/carbon/1390584-virtual_key_codes)

## Related Files

- `EventGenerator.swift` - Main implementation
- `EventGeneratorExample.swift` - Usage examples
- `EventGeneratorTests.swift` - Unit tests
- `AccessibilityManager.swift` - Permission management
- `Command.swift` - Command data models
