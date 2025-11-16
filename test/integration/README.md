# End-to-End Integration Tests

This directory contains comprehensive end-to-end integration tests for the RemoteTouch application.

## Test Coverage

### BLE Communication Flow Tests
- **Complete pairing flow**: Tests device discovery, connection, and pairing code exchange
- **Cursor movement command flow**: Verifies swipe gestures are converted to cursor move commands and sent via BLE
- **Click command flow**: Tests single tap detection and command transmission
- **Double click command flow**: Verifies tap command structure
- **Status update reception flow**: Tests receiving and processing status updates from macOS

### Mode-Specific Operation Tests
- **Presentation mode navigation**: Tests back/forward button behavior in presentation mode
- **Media control mode play/pause**: Verifies tap sends play/pause command in media mode
- **Media control mode volume**: Tests vertical swipes for volume up/down in media mode
- **Basic mouse mode buttons**: Verifies button actions in basic mouse mode

### Auto-Reconnection Flow Tests
- **Successful reconnection**: Tests automatic reconnection after unexpected disconnect
- **Failed reconnection**: Verifies behavior after maximum reconnection attempts
- **Reconnection state transitions**: Tests the complete state machine for connection states

### Command Serialization Tests
- **Cursor move command**: Verifies JSON structure with nested delta object
- **Tap command**: Tests single and double tap serialization
- **Button command**: Verifies back/forward button command structure
- **Media control command**: Tests play/pause and volume command serialization
- **Mode change command**: Verifies mode switching command structure

## Running the Tests

### Run all integration tests:
```bash
flutter test test/integration/
```

### Run specific test file:
```bash
flutter test test/integration/e2e_integration_test.dart
```

### Run with verbose output:
```bash
flutter test test/integration/ --verbose
```

## Test Architecture

The integration tests use mock implementations of key services:
- `MockBLECentralManager`: Simulates BLE communication without requiring actual Bluetooth hardware
- Mock implementations allow testing the complete flow from gesture input to command transmission

## Requirements Coverage

These tests verify all requirements from the requirements document:
- **Requirement 1**: Cursor movement via swipe gestures
- **Requirement 2**: Tap operations (single and double click)
- **Requirement 3**: Physical button operations
- **Requirement 4**: BLE pairing flow
- **Requirement 5**: Connection state and status updates
- **Requirement 7**: Mode switching (presentation, media, basic mouse)
- **Requirement 9**: Media control operations
- **Requirement 12**: Auto-reconnection functionality

## Notes

- Tests use mock BLE managers to avoid requiring physical devices
- Command throttling is tested with appropriate delays
- All tests verify the complete flow from user input to BLE command transmission
- Tests validate JSON command structure matches the protocol specification
