# CommandProcessor Implementation

## Overview

The `CommandProcessor` class is responsible for processing commands received from the iOS app via BLE and dispatching them to the `EventGenerator` to create system events on macOS.

## Architecture

```
iOS App → BLE → BLEPeripheralManager → CommandProcessor → EventGenerator → macOS System
```

## Features

### 1. Command Routing

The CommandProcessor handles the following command types:

- **CursorMoveCommand**: Moves the cursor by a specified delta
- **TapCommand**: Generates click events (single or double)
- **ButtonCommand**: Handles back/forward button actions
- **ModeChangeCommand**: Switches between control modes
- **MediaControlCommand**: Controls media playback and volume
- **PinchCommand**: Reserved for future zoom functionality

### 2. Mode-Specific Behavior

The CommandProcessor maintains a current control mode and interprets commands differently based on the mode:

#### Presentation Mode
- **Back button** → Left arrow key (previous slide)
- **Forward button** → Right arrow key (next slide)
- **Tap** → Normal click behavior

#### Basic Mouse Mode
- **Back button** → Command+Left arrow (browser back)
- **Forward button** → Enter key (confirm/open)
- **Tap** → Normal click behavior

#### Media Control Mode
- **Back button** → Left arrow (previous track/rewind)
- **Forward button** → Right arrow (next track/fast forward)
- **Single tap** → Play/Pause media
- **Swipe up** → Volume up (via MediaControlCommand)
- **Swipe down** → Volume down (via MediaControlCommand)

## Requirements Mapping

This implementation satisfies the following requirements:

- **Requirement 3.3**: Left arrow for back in presentation mode
- **Requirement 3.4**: Right arrow for forward in presentation mode
- **Requirement 3.5**: Command+Left arrow for back in basic mouse mode
- **Requirement 3.6**: Enter key for forward in basic mouse mode
- **Requirement 7.5**: Mode change handling
- **Requirement 9.4**: Media control play/pause
- **Requirement 9.5**: Media control volume adjustment

## Usage

### Basic Usage

```swift
// Create command processor
let commandProcessor = CommandProcessor()

// Process a cursor move command
let moveCommand = CursorMoveCommand(delta: CGPoint(x: 10, y: 20))
commandProcessor.processCommand(moveCommand)

// Process a tap command
let tapCommand = TapCommand(clickType: .single)
commandProcessor.processCommand(tapCommand)

// Change mode
let modeCommand = ModeChangeCommand(mode: .presentation)
commandProcessor.processCommand(modeCommand)

// Process button action (mode-specific)
let buttonCommand = ButtonCommand(action: .back)
commandProcessor.processCommand(buttonCommand)
```

### Integration with BLEPeripheralManager

The `ApplicationController` integrates the CommandProcessor with the BLE manager:

```swift
class ApplicationController: BLEPeripheralManagerDelegate {
    private let commandProcessor = CommandProcessor()
    
    func peripheralManager(_ manager: BLEPeripheralManager, didReceiveCommand command: Any) {
        // Route all received commands to the processor
        commandProcessor.processCommand(command)
    }
}
```

## Testing

The CommandProcessor includes comprehensive unit tests in `CommandProcessorTests.swift`:

- Mode change tests
- Cursor movement tests
- Tap command tests (including media mode behavior)
- Button action tests for all three modes
- Media control tests

Run tests using:
```bash
xcodebuild test -workspace Runner.xcworkspace -scheme Runner
```

## Implementation Details

### Command Type Detection

The processor uses Swift's type casting to determine the command type:

```swift
func processCommand(_ command: Any) {
    switch command {
    case let cmd as CursorMoveCommand:
        handleCursorMove(cmd)
    case let cmd as TapCommand:
        handleTap(cmd)
    // ... other cases
    }
}
```

### Mode-Specific Logic

Button actions are handled with a tuple pattern match:

```swift
switch (command.action, currentMode) {
case (.back, .presentation):
    eventGenerator.generateNavigationKey(.leftArrow)
case (.forward, .basicMouse):
    eventGenerator.generateNavigationKey(.enter)
// ... other cases
}
```

### Event Generation

The CommandProcessor delegates all system event generation to the EventGenerator:

```swift
private func handleCursorMove(_ command: CursorMoveCommand) {
    let delta = command.delta.cgPoint
    eventGenerator.moveCursor(by: delta)
}
```

## Future Enhancements

Potential improvements:

1. **Gesture History**: Track recent gestures for advanced patterns
2. **Custom Mappings**: Allow users to customize button actions per mode
3. **Pinch Zoom**: Implement zoom functionality for pinch gestures
4. **Scroll Support**: Add two-finger scroll gesture support
5. **Haptic Feedback**: Send feedback commands back to iOS for tactile response

## Related Files

- `CommandProcessor.swift` - Main implementation
- `Command.swift` - Command data models
- `EventGenerator.swift` - System event generation
- `BLEPeripheralManager.swift` - BLE communication
- `ApplicationController.swift` - Integration coordinator
- `CommandProcessorTests.swift` - Unit tests
