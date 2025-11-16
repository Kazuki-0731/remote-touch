# macOS Data Models

This directory contains the Swift data models for the RemoteTouch macOS application.

## Structure

- **Command.swift**: Command types sent from iOS to macOS
  - `CursorMoveCommand`: Cursor movement with delta
  - `TapCommand`: Single/double tap actions
  - `ButtonCommand`: Back/forward button actions
  - `ModeChangeCommand`: Control mode changes
  - `MediaControlCommand`: Media playback controls
  - `PinchCommand`: Pinch gesture data
  - `CommandParser`: Utility for parsing JSON commands

- **StatusData.swift**: Status information sent from macOS to iOS
  - Battery level
  - Timestamp
  - Connection quality

- **Device.swift**: Paired device information
  - Device ID and name
  - Peripheral UUID
  - Last connected timestamp
  - Pairing status

- **AppSettings.swift**: Application settings
  - Sensitivity (0.5-3.0x)
  - Idle timeout
  - Auto-reconnect settings
  - Max reconnect attempts

## JSON Serialization

All models conform to the `Codable` protocol and support:
- JSON encoding via `toJSON()` methods
- JSON decoding via `fromJSON()` static methods
- ISO8601 date formatting for timestamps

## Usage

These models are shared between the iOS and macOS apps to ensure consistent data exchange over BLE.

### Adding to Xcode Project

To add these files to the Xcode project:
1. Open `Runner.xcodeproj` in Xcode
2. Right-click on the Runner group
3. Select "Add Files to Runner..."
4. Navigate to `macos/Runner/Models/`
5. Select all `.swift` files
6. Ensure "Copy items if needed" is unchecked
7. Ensure "Runner" target is checked
8. Click "Add"

Alternatively, the files will be automatically discovered by Xcode when building the project.
