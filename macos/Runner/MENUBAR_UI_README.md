# Menu Bar UI Implementation

## Overview

The RemoteTouch macOS app is implemented as a menu bar application (LSUIElement) that runs in the background without appearing in the Dock. The UI consists of a menu bar icon with a dropdown menu and a pairing code window.

## Components

### 1. Menu Bar Icon

**Location**: `ApplicationController.swift` - `setupMenuBar()`

The menu bar icon changes dynamically based on the connection state:

- **Disconnected**: `antenna.radiowaves.left.and.right.slash` - Gray icon
- **Advertising**: `antenna.radiowaves.left.and.right` - Standard icon
- **Connected**: `antenna.radiowaves.left.and.right.circle.fill` - Filled icon

### 2. Menu Bar Menu

The menu contains the following items:

1. **Title**: "RemoteTouch" (disabled, header)
2. **Connection Status**: Shows current state with emoji indicators
   - ⚫ Disconnected
   - ⚡ Advertising
   - ✓ Connected
3. **Show Pairing Code** (⌘P): Opens the pairing code window
4. **Accessibility Permission** (⌘A): Checks and displays permission status
   - ✓ Accessibility Permission Granted
   - ⚠️ Accessibility Permission Required
5. **Quit RemoteTouch** (⌘Q): Terminates the application

### 3. Pairing Code Window

**Location**: `PairingWindowController.swift`

A modal window that displays:
- Title: "Pairing Code"
- Large formatted code (e.g., "123 456")
- Instructions: "Enter this code on your iPhone to pair"
- Status message with color coding:
  - Gray: "Waiting for pairing..."
  - Green: "✓ Paired with [device name]"
  - Red: "✗ [error message]"
  - Orange: "⚠️ Locked out. Try again in Xm Ys"
- Progress indicator (spinning) while waiting
- Cancel/Close button

## Features

### Dynamic Updates

The menu updates automatically when:
- Connection state changes (via `BLEPeripheralManagerDelegate`)
- Menu is opened (via `NSMenuDelegate.menuWillOpen`)
- Accessibility permission changes

### Connection State Management

Connection states are tracked through the `BLEPeripheralManager`:
- `isAdvertising`: BLE advertising is active
- `isConnected`: iOS device is connected

### Pairing Flow

1. iOS device requests pairing
2. macOS generates 6-digit code
3. Pairing window automatically opens via delegate callback
4. User enters code on iOS device
5. Window shows success/failure
6. Auto-closes after 2 seconds on success

### Accessibility Permission

The app checks accessibility permission:
- On startup
- When menu item is clicked
- Shows alert with "Open System Preferences" button
- Updates menu item status dynamically

## Configuration

### Info.plist Settings

```xml
<key>LSUIElement</key>
<true/>
```

This makes the app a menu bar-only application (no Dock icon).

### AppDelegate Configuration

```swift
override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
}
```

Prevents app from quitting when windows are closed.

## Requirements Satisfied

### Requirement 4.2
✅ Pairing code display on macOS
- Pairing code window shows 6-digit code
- Automatically opens when pairing is requested
- Shows success/failure status

### Requirement 10.2
✅ Accessibility permission management
- Menu item shows permission status
- Alert dialog prompts user to grant permission
- Opens System Preferences when requested

## Usage

### For Users

1. **Launch App**: App appears in menu bar (no Dock icon)
2. **Check Status**: Click menu bar icon to see connection status
3. **Pair Device**: 
   - Click "Show Pairing Code" or wait for iOS device to request pairing
   - Enter code on iPhone
4. **Grant Permissions**: Click accessibility menu item if permission needed
5. **Quit**: Select "Quit RemoteTouch" from menu

### For Developers

#### Update Menu Status
```swift
updateMenuBarStatus()
```

#### Show Pairing Code Manually
```swift
applicationController.showPairingCode()
```

#### Check Accessibility
```swift
accessibilityManager.checkPermission()
```

## Testing

### Manual Testing Checklist

- [ ] Menu bar icon appears on launch
- [ ] Icon changes based on connection state
- [ ] Menu items display correct status
- [ ] Pairing code window opens and displays code
- [ ] Pairing success shows green message
- [ ] Pairing failure shows red message
- [ ] Lockout shows orange message with countdown
- [ ] Accessibility permission check works
- [ ] System Preferences opens when requested
- [ ] Quit terminates the application
- [ ] App doesn't appear in Dock
- [ ] App doesn't quit when windows close

### Integration Testing

The menu bar UI integrates with:
- `BLEPeripheralManager`: Connection state updates
- `PairingManager`: Pairing code generation and verification
- `AccessibilityManager`: Permission checking
- `CommandProcessor`: Command handling (indirect)

## Future Enhancements

Potential improvements:
- Show connected device name in menu
- Display battery level of connected device
- Add "Disconnect" menu item when connected
- Show list of paired devices
- Add preferences window for settings
- Notification center integration
- Keyboard shortcuts for common actions
