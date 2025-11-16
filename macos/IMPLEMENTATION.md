# macOS App Implementation

## Overview

This document describes the macOS application structure for RemoteTouch, which acts as a BLE peripheral server that receives commands from the iOS app and generates system events.

## Project Structure

```
macos/Runner/
├── Models/              # Data models (Task 11 - COMPLETED)
│   ├── Command.swift    # Command types from iOS
│   ├── StatusData.swift # Status sent to iOS
│   ├── Device.swift     # Paired device info
│   ├── AppSettings.swift # App settings
│   ├── ModelsTests.swift # Unit tests
│   └── README.md        # Documentation
├── Services/            # Business logic (Future tasks)
│   └── .gitkeep
├── AppDelegate.swift    # App entry point
└── MainFlutterWindow.swift # Flutter integration
```

## Completed: Task 11 - Data Models Setup

### Implementation Details

#### 1. Command Models (Command.swift)

All command types that can be sent from iOS to macOS:

- **CursorMoveCommand**: Cursor movement with delta (dx, dy)
- **TapCommand**: Single or double tap actions
- **ButtonCommand**: Back/forward button actions
- **ModeChangeCommand**: Switch between presentation/media/mouse modes
- **MediaControlCommand**: Play/pause, volume up/down
- **PinchCommand**: Pinch gesture with scale factor

**Key Features:**
- All commands conform to `Codable` protocol
- JSON serialization/deserialization support
- `CommandParser` utility for parsing incoming JSON
- Type-safe enum-based command types

#### 2. Status Data Model (StatusData.swift)

Status information sent from macOS to iOS:

- Battery level (0-100)
- Timestamp (ISO8601 format)
- Connection quality (0-100)

**Key Features:**
- ISO8601 date encoding/decoding
- `toJSON()` and `fromJSON()` convenience methods
- CustomStringConvertible for debugging

#### 3. Device Model (Device.swift)

Represents a paired iOS device:

- Unique ID
- Device name
- Peripheral UUID
- Last connected timestamp
- Pairing status

**Key Features:**
- Identifiable, Equatable, Hashable protocols
- `copyWith()` method for immutable updates
- ISO8601 date handling

#### 4. App Settings Model (AppSettings.swift)

Application configuration:

- Sensitivity (0.5-3.0x, default: 1.0)
- Idle timeout (default: 60 seconds)
- Auto-reconnect (default: true)
- Max reconnect attempts (default: 10)

**Key Features:**
- Default values for all properties
- `copyWith()` method for updates
- Equatable and Hashable support

### JSON Serialization

All models support JSON encoding/decoding:

```swift
// Encoding
let status = StatusData(batteryLevel: 85, connectionQuality: 95)
let jsonData = try status.toJSON()

// Decoding
let decoded = try StatusData.fromJSON(jsonData)
```

### Testing

All models have been tested with unit tests in `ModelsTests.swift`:

- ✓ Command encoding/decoding
- ✓ StatusData serialization
- ✓ Device model operations
- ✓ AppSettings configuration
- ✓ ISO8601 date handling
- ✓ copyWith() methods

Test results show 100% success rate for all data model operations.

## Requirements Coverage

This implementation satisfies the following requirements:

- **1.2**: macOS App receives cursor movement commands
- **2.2**: macOS App receives click commands
- **4.4**: Device pairing data structures
- **5.3**: Status data transmission structure
- **7.5**: Mode change command structure
- **9.4**: Media control command structure

## Next Steps

The following tasks will build upon these data models:

- **Task 12**: BLE Peripheral Manager (uses Command and StatusData)
- **Task 13**: Pairing functionality (uses Device model)
- **Task 15**: CGEvent API integration (processes Command types)
- **Task 16**: Command processor (uses all command types)
- **Task 17**: Status transmission (uses StatusData)

## Integration with Xcode

To use these models in the Xcode project:

1. Open `Runner.xcodeproj` in Xcode
2. The Swift files in `Models/` directory will be automatically discovered
3. Alternatively, manually add them:
   - Right-click Runner group → "Add Files to Runner..."
   - Select all `.swift` files in `Models/`
   - Ensure "Runner" target is checked

## Architecture Notes

The data models follow these principles:

1. **Immutability**: Use `copyWith()` for updates
2. **Type Safety**: Enums for all categorical data
3. **Codable**: Full JSON serialization support
4. **Protocol Conformance**: Identifiable, Equatable, Hashable where appropriate
5. **Error Handling**: Proper error types for parsing failures
6. **Documentation**: Inline comments for all public APIs

## Compatibility

- **Minimum macOS Version**: macOS 12.0 (Monterey)
- **Swift Version**: Swift 5.0+
- **Dependencies**: Foundation, CoreGraphics (system frameworks)
