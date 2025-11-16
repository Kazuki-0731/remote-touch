# Pairing Implementation

This document describes the pairing functionality implementation for RemoteTouch macOS app.

## Overview

The pairing system uses a 6-digit code verification mechanism to securely pair iOS devices with the macOS app. The implementation follows the requirements specified in the design document.

## Components

### 1. PairingManager.swift

Core pairing logic manager that handles:

- **6-digit code generation**: Generates random 6-digit codes (000000-999999)
- **Code verification**: Validates codes submitted by iOS devices
- **Lockout mechanism**: Locks out pairing after 3 failed attempts for 5 minutes
- **Device storage**: Persists paired devices using UserDefaults
- **Timeout handling**: Pairing codes expire after 60 seconds

#### Key Methods

```swift
func generatePairingCode(for central: CBCentral) -> String
func verifyPairingCode(_ code: String, from central: CBCentral, deviceName: String) -> Bool
func isDevicePaired(_ centralIdentifier: UUID) -> Bool
func loadPairedDevices() -> [Device]
func removePairedDevice(_ deviceId: String) throws
func isLockedOut() -> Bool
func getRemainingLockoutTime() -> TimeInterval?
```

#### Security Features

- **3-attempt limit**: After 3 failed verification attempts, pairing is locked for 5 minutes
- **Code timeout**: Pairing codes expire after 60 seconds
- **Central verification**: Ensures the device requesting pairing matches the device that initiated the request
- **Persistent lockout**: Lockout state is saved to UserDefaults and survives app restarts

### 2. BLEPeripheralManager.swift (Updated)

Enhanced with pairing functionality:

- **Pairing characteristic handling**: Implements read/write handlers for pairing characteristic
- **Delegate methods**: Notifies delegates of pairing events
- **Device management**: Provides access to paired devices list
- **Last connected tracking**: Updates device last connected timestamp on connection

#### Pairing Flow

1. **iOS reads pairing characteristic**:
   - macOS checks if device is already paired → returns "paired" status
   - macOS checks if locked out → returns "locked" status with remaining time
   - macOS generates new 6-digit code → returns "pending" status with code

2. **iOS writes pairing characteristic**:
   - iOS sends JSON with `code` and `deviceName`
   - macOS verifies code against expected value
   - On success: Device is saved to paired devices list
   - On failure: Failed attempt counter increments, may trigger lockout

### 3. PairingWindowController.swift

UI component for displaying pairing code to user:

- **Code display**: Shows formatted 6-digit code (e.g., "123 456")
- **Status updates**: Shows pairing status (waiting, success, failure, lockout)
- **Auto-close**: Automatically closes 2 seconds after successful pairing
- **Lockout display**: Shows remaining lockout time in minutes and seconds

#### UI Features

- Large, readable code display (48pt font)
- Clear instructions for user
- Status messages with color coding:
  - Green: Success
  - Red: Failure
  - Orange: Lockout warning
- Cancel button to dismiss window

## Data Flow

### Pairing Request Flow

```
iOS Device                    macOS App
    |                             |
    |-- Read Pairing Char ------->|
    |                             | Generate code
    |                             | Show code on screen
    |<-- Return code -------------|
    |                             |
    | User enters code            |
    |                             |
    |-- Write Pairing Char ------>|
    |    (code + deviceName)      | Verify code
    |                             | Save device
    |<-- Success/Failure ---------|
```

### Device Storage

Paired devices are stored in UserDefaults as JSON array:

```json
[
  {
    "id": "UUID-STRING",
    "name": "User's iPhone",
    "peripheralUUID": "UUID-STRING",
    "lastConnected": "2025-11-17T10:30:00Z",
    "isPaired": true
  }
]
```

## Requirements Mapping

This implementation satisfies the following requirements:

- **4.2**: macOS App generates 6-digit pairing code and displays on screen ✓
- **4.3**: iOS App sends pairing code to macOS App via BLE ✓
- **4.4**: macOS App verifies correct pairing code and establishes pairing ✓
- **4.5**: macOS App rejects incorrect pairing code with error message ✓
  - Includes 3-attempt limit with 5-minute lockout

## Usage Example

### In macOS App

```swift
// Initialize BLE Peripheral Manager
let bleManager = BLEPeripheralManager()
bleManager.delegate = self

// Start advertising
bleManager.startAdvertising()

// Implement delegate methods
extension MyClass: BLEPeripheralManagerDelegate {
    func peripheralManager(_ manager: BLEPeripheralManager, 
                          didGeneratePairingCode code: String) {
        // Show pairing window with code
        pairingWindow.showPairingCode(code)
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, 
                          didCompletePairingWith device: Device) {
        // Show success
        pairingWindow.showPairingSuccess(deviceName: device.name)
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, 
                          didFailPairingWithError error: PairingError) {
        // Show error
        pairingWindow.showPairingFailure(error: error.localizedDescription)
    }
}
```

### Checking Paired Devices

```swift
// Get all paired devices
let devices = bleManager.getPairedDevices()

// Check if specific device is paired
let isPaired = bleManager.isDevicePaired(centralIdentifier)

// Remove a device
try bleManager.removePairedDevice(deviceId)
```

## Testing

### Manual Testing Steps

1. **Normal Pairing Flow**:
   - Start macOS app
   - Start iOS app and scan for devices
   - Verify 6-digit code appears on macOS screen
   - Enter code on iOS device
   - Verify pairing succeeds

2. **Invalid Code**:
   - Start pairing flow
   - Enter incorrect code on iOS
   - Verify error message appears
   - Verify can retry

3. **Lockout Mechanism**:
   - Start pairing flow
   - Enter incorrect code 3 times
   - Verify lockout message appears
   - Verify cannot pair for 5 minutes
   - Wait 5 minutes
   - Verify can pair again

4. **Code Timeout**:
   - Start pairing flow
   - Wait 60+ seconds
   - Try to enter code
   - Verify code expired error

5. **Already Paired**:
   - Pair device successfully
   - Try to pair same device again
   - Verify returns "already paired" status

## Future Enhancements

- QR code display option for easier pairing
- Biometric authentication on iOS side
- Multiple simultaneous pairing requests
- Pairing history and audit log
- Custom lockout duration settings
