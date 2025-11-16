# macOS End-to-End Integration Tests

This document describes the end-to-end integration tests for the macOS side of the RemoteTouch application.

## Test File: E2EIntegrationTests.swift

### Overview
The E2E integration tests verify the complete flow of command processing from BLE reception through to system event generation on macOS.

## Test Coverage

### 1. Pairing Flow Tests

#### `testE2E_CompletePairingFlow()`
Tests the complete device pairing process:
- Generates a 6-digit pairing code
- Verifies the code is numeric and correct length
- Tests code verification with correct code
- Tests code verification with incorrect code

#### `testE2E_PairingCodeLockout()`
Tests the security lockout mechanism:
- Attempts 3 incorrect pairing codes
- Verifies lockout state is activated
- Confirms even correct codes fail during lockout

### 2. BLE Communication Flow Tests

#### `testE2E_ReceiveAndProcessCursorMoveCommand()`
Tests the complete cursor movement flow:
1. Simulates receiving cursor move command from iOS via BLE
2. Parses the JSON command data
3. Processes the command through CommandProcessor
4. Verifies EventGenerator receives correct cursor delta values

#### `testE2E_ReceiveAndProcessTapCommand()`
Tests single click processing:
1. Receives tap command with "single" click type
2. Processes through command processor
3. Verifies single click event is generated

#### `testE2E_ReceiveAndProcessDoubleTapCommand()`
Tests double click processing:
1. Receives tap command with "double" click type
2. Processes through command processor
3. Verifies double click event is generated

#### `testE2E_SendStatusUpdate()`
Tests status update transmission:
1. Creates StatusData with battery level and connection quality
2. Encodes to JSON
3. Simulates sending via BLE
4. Verifies data was transmitted correctly

### 3. Mode-Specific Operation Tests

#### `testE2E_PresentationMode_NavigationButtons()`
Tests presentation mode button behavior:
- Sets mode to presentation
- Processes back button → verifies left arrow key
- Processes forward button → verifies right arrow key

#### `testE2E_MediaControlMode_PlayPause()`
Tests media control play/pause:
- Sets mode to media control
- Processes play/pause command
- Verifies media control event is generated

#### `testE2E_MediaControlMode_VolumeControl()`
Tests media control volume adjustment:
- Sets mode to media control
- Processes volume up command → verifies volume up event
- Processes volume down command → verifies volume down event

#### `testE2E_BasicMouseMode_ButtonActions()`
Tests basic mouse mode button behavior:
- Sets mode to basic mouse
- Processes back button → verifies Command+Left key
- Processes forward button → verifies Enter key

### 4. Mode Change Tests

#### `testE2E_ModeChangeCommand()`
Tests switching between all control modes:
- Iterates through presentation, mediaControl, and basicMouse modes
- Verifies each mode change command is processed correctly
- Confirms CommandProcessor mode state updates

### 5. Complete User Scenario Tests

#### `testE2E_CompleteUserScenario_PresentationControl()`
Simulates a complete presentation control session:
1. Pairs devices with pairing code
2. Switches to presentation mode
3. Moves cursor to click on presentation
4. Clicks to start presentation
5. Navigates slides with forward/back buttons

#### `testE2E_CompleteUserScenario_MediaControl()`
Simulates a complete media control session:
1. Switches to media control mode
2. Plays/pauses media
3. Adjusts volume up
4. Adjusts volume down

## Mock Components

### MockBLEPeripheralManager
Simulates BLE peripheral functionality:
- `simulateCommandReceived()`: Simulates receiving command from iOS
- `simulateStatusSent()`: Simulates sending status to iOS
- `startAdvertising()` / `stopAdvertising()`: Controls advertising state

### MockEventGenerator
Extends EventGenerator to capture generated events:
- Tracks last cursor delta
- Tracks last click type
- Tracks last navigation key
- Tracks last media action

## Command Protocol

The tests verify the following JSON command structures:

### Cursor Move
```json
{
  "type": "cursorMove",
  "deltaX": 15.0,
  "deltaY": 25.0
}
```

### Tap
```json
{
  "type": "tap",
  "clickType": "single" | "double"
}
```

### Button
```json
{
  "type": "button",
  "action": "back" | "forward"
}
```

### Media Control
```json
{
  "type": "mediaControl",
  "action": "playPause" | "volumeUp" | "volumeDown"
}
```

### Mode Change
```json
{
  "type": "modeChange",
  "mode": "presentation" | "mediaControl" | "basicMouse"
}
```

## Running the Tests

### Via Xcode
1. Open `Runner.xcodeproj` in Xcode
2. Select the RunnerTests scheme
3. Press Cmd+U to run all tests
4. Or use Test Navigator (Cmd+6) to run specific tests

### Via Command Line
```bash
cd macos
xcodebuild test -project Runner.xcodeproj -scheme Runner -destination 'platform=macOS'
```

### Run specific test class
```bash
xcodebuild test -project Runner.xcodeproj -scheme Runner -destination 'platform=macOS' -only-testing:RunnerTests/E2EIntegrationTests
```

## Requirements Coverage

These tests verify the following requirements:

- **Requirement 1.2**: macOS receives and processes cursor movement commands
- **Requirement 2.2**: macOS generates click events via CGEvent API
- **Requirement 3.3-3.6**: Mode-specific button actions
- **Requirement 4.2-4.5**: Pairing code generation and verification
- **Requirement 5.3**: Status data transmission
- **Requirement 7.5**: Mode change processing
- **Requirement 9.4-9.5**: Media control event generation

## Notes

- Tests use mock implementations to avoid requiring actual BLE hardware
- EventGenerator methods are tested for non-crashing behavior
- Actual CGEvent generation requires accessibility permissions (tested manually)
- All tests verify the complete command processing pipeline
- JSON parsing and command routing are thoroughly tested

## Integration with iOS Tests

These macOS tests complement the iOS integration tests in `test/integration/e2e_integration_test.dart`:
- iOS tests verify command generation and transmission
- macOS tests verify command reception and processing
- Together they validate the complete end-to-end flow
