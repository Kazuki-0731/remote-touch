# Services Directory

This directory contains the core service classes for the RemoteTouch macOS application.

## BLEPeripheralManager

The `BLEPeripheralManager` class handles all Bluetooth Low Energy server functionality for the macOS app.

### Features

- **BLE Advertising**: Advertises the RemoteTouch service to nearby iOS devices
- **GATT Service Setup**: Configures the custom GATT service with three characteristics:
  - Command Characteristic (Write): Receives commands from iOS
  - Status Characteristic (Notify): Sends status updates to iOS
  - Pairing Characteristic (Read/Write): Handles pairing code exchange
- **Command Reception**: Receives and parses commands from iOS devices
- **Status Transmission**: Sends battery level and connection quality every 2 seconds
- **Connection Management**: Tracks connection state and manages connected devices

### Usage Example

```swift
// Create the BLE Peripheral Manager
let bleManager = BLEPeripheralManager()
bleManager.delegate = self

// Start advertising
bleManager.startAdvertising()

// Send status updates
let status = StatusData(
    batteryLevel: 85,
    timestamp: Date(),
    connectionQuality: 100
)
bleManager.sendStatus(status)

// Stop advertising
bleManager.stopAdvertising()
```

### Delegate Protocol

Implement `BLEPeripheralManagerDelegate` to receive events:

```swift
extension MyClass: BLEPeripheralManagerDelegate {
    func peripheralManager(_ manager: BLEPeripheralManager, didReceiveCommand command: Any) {
        // Handle received command
        if let cursorMove = command as? CursorMoveCommand {
            // Process cursor movement
        }
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didUpdateConnectionState isConnected: Bool) {
        // Handle connection state changes
        print("Connection state: \(isConnected ? "Connected" : "Disconnected")")
    }
}
```

### Requirements Satisfied

- **Requirement 4.1**: BLE device scanning and connection (peripheral side)
- **Requirement 4.2**: Pairing code generation and display (foundation for task 13)
- **Requirement 5.3**: Status transmission every 2 seconds with battery level

### Technical Details

- Uses Core Bluetooth framework (`CBPeripheralManager`)
- Service UUID: `12345678-1234-1234-1234-123456789ABC`
- Command Characteristic UUID: `12345678-1234-1234-1234-123456789ABD`
- Status Characteristic UUID: `12345678-1234-1234-1234-123456789ABE`
- Pairing Characteristic UUID: `12345678-1234-1234-1234-123456789ABF`
- Battery level retrieved using IOKit framework
- Status updates sent every 2 seconds when connected

### Dependencies

- CoreBluetooth framework
- IOKit framework (for battery level)
- Command.swift (for command parsing)
- StatusData.swift (for status encoding)

### Next Steps

The pairing functionality (task 13) will extend this class to:
- Generate 6-digit pairing codes
- Validate pairing codes from iOS devices
- Implement lockout after 3 failed attempts
