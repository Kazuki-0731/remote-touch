# End-to-End Integration Test Guide

This guide provides comprehensive instructions for running and understanding the end-to-end integration tests for the RemoteTouch application.

## Overview

The RemoteTouch application has comprehensive E2E integration tests covering:
- **iOS/Flutter Tests**: Command generation, BLE communication, gesture processing
- **macOS/Swift Tests**: Command reception, processing, and system event generation

## Test Architecture

```
┌─────────────────────────────────────┐
│     iOS Integration Tests           │
│  (test/integration/)                │
│                                     │
│  - Gesture → Command conversion    │
│  - BLE command transmission        │
│  - Mode switching                  │
│  - Auto-reconnection               │
└──────────────┬──────────────────────┘
               │
               │ BLE Protocol
               │
┌──────────────▼──────────────────────┐
│    macOS Integration Tests          │
│  (macos/RunnerTests/)               │
│                                     │
│  - Command reception & parsing     │
│  - Command processing              │
│  - CGEvent generation              │
│  - Pairing flow                    │
└─────────────────────────────────────┘
```

## Running iOS/Flutter Tests

### Prerequisites
- Flutter SDK installed
- Project dependencies installed (`flutter pub get`)

### Run All Integration Tests
```bash
flutter test test/integration/
```

### Run Specific Test File
```bash
flutter test test/integration/e2e_integration_test.dart
```

### Run with Verbose Output
```bash
flutter test test/integration/ --verbose
```

### Run Specific Test Group
```bash
flutter test test/integration/e2e_integration_test.dart --name "BLE Communication Flow"
```

### Expected Output
```
00:01 +17: All tests passed!
```

## Running macOS/Swift Tests

### Prerequisites
- Xcode installed
- macOS project dependencies installed (`pod install` in macos directory)

### Via Xcode GUI
1. Open `macos/Runner.xcodeproj` in Xcode
2. Select the "Runner" scheme
3. Press `Cmd+U` to run all tests
4. Or use Test Navigator (`Cmd+6`) to run specific tests

### Via Command Line
```bash
cd macos
xcodebuild test -project Runner.xcodeproj -scheme Runner -destination 'platform=macOS'
```

### Run Specific Test Class
```bash
cd macos
xcodebuild test -project Runner.xcodeproj -scheme Runner \
  -destination 'platform=macOS' \
  -only-testing:RunnerTests/E2EIntegrationTests
```

### Run Specific Test Method
```bash
cd macos
xcodebuild test -project Runner.xcodeproj -scheme Runner \
  -destination 'platform=macOS' \
  -only-testing:RunnerTests/E2EIntegrationTests/testE2E_CompletePairingFlow
```

## Test Coverage Summary

### iOS Tests (17 tests)

#### BLE Communication Flow (5 tests)
- ✅ Complete pairing flow
- ✅ Cursor movement command flow
- ✅ Click command flow
- ✅ Double click command flow
- ✅ Status update reception flow

#### Mode-Specific Operations (4 tests)
- ✅ Presentation mode navigation buttons
- ✅ Media control mode play/pause
- ✅ Media control mode volume control
- ✅ Basic mouse mode button actions

#### Auto-Reconnection Flow (3 tests)
- ✅ Successful reconnection after disconnect
- ✅ Failed reconnection after max attempts
- ✅ Reconnection state transitions

#### Command Serialization (5 tests)
- ✅ Cursor move command serialization
- ✅ Tap command serialization
- ✅ Button command serialization
- ✅ Media control command serialization
- ✅ Mode change command serialization

### macOS Tests (13 tests)

#### Pairing Flow (2 tests)
- ✅ Complete pairing flow
- ✅ Pairing code lockout

#### BLE Communication Flow (4 tests)
- ✅ Receive and process cursor move command
- ✅ Receive and process tap command
- ✅ Receive and process double tap command
- ✅ Send status update

#### Mode-Specific Operations (4 tests)
- ✅ Presentation mode navigation buttons
- ✅ Media control mode play/pause
- ✅ Media control mode volume control
- ✅ Basic mouse mode button actions

#### Mode Change (1 test)
- ✅ Mode change command

#### Complete User Scenarios (2 tests)
- ✅ Complete presentation control scenario
- ✅ Complete media control scenario

## Requirements Coverage

The E2E tests verify all requirements from the requirements document:

| Requirement | Description | iOS Tests | macOS Tests |
|-------------|-------------|-----------|-------------|
| 1.1-1.4 | Cursor movement via swipe | ✅ | ✅ |
| 2.1-2.4 | Tap operations | ✅ | ✅ |
| 3.1-3.6 | Button operations | ✅ | ✅ |
| 4.1-4.5 | BLE pairing | ✅ | ✅ |
| 5.1-5.4 | Connection status | ✅ | ✅ |
| 6.1-6.4 | Device storage | ⚠️ Unit tests | N/A |
| 7.1-7.5 | Mode switching | ✅ | ✅ |
| 8.1-8.4 | Sensitivity settings | ⚠️ Unit tests | N/A |
| 9.1-9.5 | Media control | ✅ | ✅ |
| 10.1-10.4 | Accessibility | N/A | ⚠️ Manual |
| 11.1-11.4 | Idle detection | ⚠️ Unit tests | N/A |
| 12.1-12.4 | Auto-reconnection | ✅ | N/A |

Legend:
- ✅ Covered by E2E tests
- ⚠️ Covered by unit tests or requires manual testing
- N/A Not applicable to this platform

## Manual Testing Scenarios

Some scenarios require manual testing with actual devices:

### 1. Complete Pairing Flow (Manual)
1. Start macOS app
2. Start iOS app
3. Scan for devices on iOS
4. Verify macOS appears in device list
5. Initiate pairing from iOS
6. Verify 6-digit code appears on macOS
7. Enter code on iOS
8. Verify successful pairing

### 2. Cursor Movement (Manual)
1. Pair devices
2. Swipe on iOS touchpad
3. Verify Mac cursor moves correspondingly
4. Test different swipe speeds
5. Verify sensitivity settings affect movement

### 3. Mode Switching (Manual)
1. Switch to Presentation mode
2. Test back/forward buttons control slides
3. Switch to Media Control mode
4. Test tap for play/pause
5. Test vertical swipes for volume
6. Switch to Basic Mouse mode
7. Test standard mouse operations

### 4. Auto-Reconnection (Manual)
1. Establish connection
2. Move Mac out of Bluetooth range
3. Verify iOS shows "Reconnecting" state
4. Move Mac back in range
5. Verify automatic reconnection
6. Test max retry limit by staying out of range

### 5. Accessibility Permissions (Manual - macOS)
1. Launch macOS app without accessibility permission
2. Verify permission request dialog appears
3. Grant permission in System Preferences
4. Verify app functions correctly
5. Revoke permission
6. Verify app handles gracefully

## Troubleshooting

### iOS Tests Failing

**Issue**: Tests fail with "Cannot send command: not connected"
**Solution**: Ensure mock BLE manager is set to connected state before testing

**Issue**: Tests fail with timing issues
**Solution**: Increase delay durations in tests for async operations

### macOS Tests Failing

**Issue**: Build fails with plugin dependency errors
**Solution**: Run `pod install` in macos directory and rebuild

**Issue**: Tests fail with "Module not found"
**Solution**: Ensure all Swift files are added to the test target

### General Issues

**Issue**: Tests pass but manual testing fails
**Solution**: E2E tests use mocks - verify actual BLE implementation separately

**Issue**: Inconsistent test results
**Solution**: Check for race conditions in async operations

## Continuous Integration

### GitHub Actions Example
```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  ios-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/integration/
  
  macos-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - run: cd macos && pod install
      - run: cd macos && xcodebuild test -project Runner.xcodeproj -scheme Runner -destination 'platform=macOS'
```

## Best Practices

1. **Run tests before committing**: Ensure all E2E tests pass
2. **Update tests with features**: Add E2E tests for new functionality
3. **Keep mocks synchronized**: Ensure mocks match actual implementations
4. **Document manual tests**: Record results of manual testing scenarios
5. **Test on real devices**: Periodically verify with actual hardware

## Next Steps

After E2E tests pass:
1. Perform manual testing with real devices
2. Test edge cases (low battery, poor connection, etc.)
3. Conduct user acceptance testing
4. Prepare for deployment

## Support

For issues or questions about the E2E tests:
1. Check test output for specific error messages
2. Review test documentation in `test/integration/README.md` and `macos/RunnerTests/E2E_INTEGRATION_README.md`
3. Verify all prerequisites are met
4. Check that mocks are properly configured
