# RemoteTouch

![CI/CD](https://github.com/Kazuki-0731/remote-touch/actions/workflows/flutter-ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS-lightgrey.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart)
![Swift](https://img.shields.io/badge/Swift-5.0%2B-FA7343?logo=swift)
![Kotlin](https://img.shields.io/badge/Kotlin-1.9%2B-7F52FF?logo=kotlin)

A Bluetooth Low Energy (BLE) connected app that allows you to use your iPhone/Android as a macOS touchpad.

## Overview

RemoteTouch is an app that enables you to use your smartphone as a wireless touchpad for Mac. Through Bluetooth connection, it realizes cursor operations, clicks, and browser navigation (back/forward).

### Architecture

```
┌─────────────────┐          BLE          ┌─────────────────┐
│  iOS / Android  │ ────────────────────► │     macOS       │
│  (Remote Side)  │  BLE Peripheral      │  (Receiver)     │
│  Touchpad Ops   │  Advertise & Send    │  BLE Central    │
│                 │  Commands            │  Scan & Connect │
└─────────────────┘                      └─────────────────┘
```

**Architecture Features:**
- iOS/Android app advertises as **BLE Peripheral**
- macOS app scans and connects as **BLE Central**
- iOS/Android sends commands (touchpad operations, button clicks, etc.) in JSON format
- macOS receives commands and generates system events via CGEvent API

## Key Features

### Touchpad Operations
- **Swipe**: Cursor movement (supports vertical and horizontal directions)
- **Single Tap**: Left click (cursor position unchanged)
- **Double Tap**: Double click (cursor position unchanged)
- **Visual Feedback on Touch**: Blue border lights up on touch
- **Sensitivity Adjustment**: Adjustable from 0.5x to 3.0x

### Control Modes
Three switchable modes:

1. **Basic Mouse Mode**
   - Standard mouse operations
   - Back/Forward buttons

2. **Presentation Mode**
   - Optimized for presentation operations
   - Previous/Next slide buttons

3. **Media Control Mode**
   - Media playback operations
   - Play/Pause, Volume buttons

### Mode-Specific Button Layout
- **Basic Mouse Mode**: Back (◀) / Forward (▶)
- **Presentation Mode**: Previous (◀) / Next (▶)
- **Media Control Mode**: Play/Pause (▶) / Volume (🔊)
- **Ripple Effect**: Visual feedback on button tap

### Settings Screen
- **Control Mode**: Navigate to mode selection screen
- **Touchpad Sensitivity**: Adjust sensitivity with slider (0.5x - 3.0x)
- **About**: Display app information
- **Settings Persistence**: Auto-save and restore settings with SharedPreferences

### BLE Connection
- **Auto-Advertise**: Automatically start BLE advertising when Android app launches
- **Auto-Connect**: macOS automatically detects and connects to nearby devices
- **Connection Status Display**: Real-time connection status (Bluetooth icon)

## Setup

### Requirements

- **macOS**: macOS 10.15 (Catalina) or later
- **iOS**: iOS 15.0 or later (not yet implemented)
- **Android**: Android 12.0 (API 31) or later, BLE Peripheral-compatible device
- **Flutter**: 3.0 or later
- **Bluetooth**: Both devices must support Bluetooth 4.0 (BLE) or later

### Installation Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/Kazuki-0731/remote-touch.git
cd remote-touch
```

#### 2. Install Dependencies

```bash
flutter pub get
cd macos && pod install && cd ..
```

#### 3. Build and Install macOS App

**Method 1: Using Makefile (Recommended)**
```bash
make install-macos
```

This command will:
1. Create a release build
2. Install to /Applications/remote_touch.app
3. Make it launchable from Spotlight

**Method 2: Manual Build**
```bash
flutter build macos --release
cp -R build/macos/Build/Products/Release/remote_touch.app /Applications/
```

**Important**: Please grant **Accessibility Permission** on first launch.
- System Settings > Privacy & Security > Accessibility
- Add remote_touch app to the allowed list

#### 4. Build and Run Android App

```bash
flutter run -d <android-device-id>
```

Check device ID:
```bash
flutter devices
```

## Usage

### Prerequisites
1. **Bluetooth is ON on both devices**
2. **Accessibility permission is granted on macOS side**
3. **iOS/Android and macOS are nearby** (BLE communication range: about 10m)

### Connection Steps

#### 1. Launch macOS App

```bash
open /Applications/remote_touch.app
```

Or search for "remote_touch" from Spotlight

- RemoteTouch icon will appear in the menu bar
- The app automatically starts BLE scanning

#### 2. Start Advertising on Android App

1. Launch RemoteTouch app on your smartphone
2. The app automatically starts BLE advertising
3. When the macOS app detects your smartphone, it automatically connects
4. When connection succeeds, the touchpad screen will appear

#### 3. Touchpad Operations

**Screen Layout:**
```
┌─────────────────────────────────┐
│ RemoteTouch   🔵 Connected    ⚙️│
├─────────────────────────────────┤
│                                 │
│   ┌─────────────────────────┐   │
│   │                         │   │
│   │                         │   │
│   │      Touchpad           │   │
│   │      Area               │   │
│   │                         │   │
│   │  (Lights up blue on     │   │
│   │   touch)                │   │
│   └─────────────────────────┘   │
│                                 │
│   ┌──────────┐   ┌──────────┐   │
│   │  ◀ Back  │   │ Forward ▶│   │
│   └──────────┘   └──────────┘   │
└─────────────────────────────────┘
```

**Basic Operations:**
- **Swipe**: Swipe on touchpad area to move cursor
  - Swipe down → Cursor moves down
  - Swipe up → Cursor moves up
  - Same for horizontal direction
- **Tap**: Tap once for left click (cursor doesn't move)
- **Double Tap**: Tap twice quickly for double click (cursor doesn't move)

**Settings Screen:**
- Tap the ⚙️ icon on the top right of AppBar
- **Control Mode**: Mode selection (Basic Mouse / Presentation / Media Control)
  - Tap to select from three modes
  - Selected mode is automatically saved
- **Touchpad Sensitivity**: Adjust sensitivity (50% - 300%)
  - Drag the slider to adjust
  - Adjusted sensitivity is automatically saved
- **About**: App information
- **Save Settings**: Settings are automatically saved when you go back and restored on next launch

**Mode-Specific Buttons:**
- **Basic Mouse Mode**:
  - Back (◀): Go back in browser/Finder (Command+←)
  - Forward (▶): Go forward in browser/Finder (Command+→)
- **Presentation Mode**:
  - Previous (◀): Previous slide (Command+←)
  - Next (▶): Next slide (Command+→)
- **Media Control Mode**:
  - Play/Pause (▶): Play/Pause
  - Volume (🔊): Volume up

## Makefile Commands

The project includes a Makefile for build automation:

### macOS Commands
```bash
make install-macos    # Build and install to /Applications (recommended)
make build-macos      # Release build only
make run-macos        # Launch installed app
make clean-macos      # Clean macOS build
make dev-macos        # Run in debug mode
```

### iOS Commands
```bash
make build-ios        # iOS release build
make run-ios          # Run on device/simulator
make clean-ios        # Clean iOS build and Pods
make dev-ios          # Run in debug mode
```

### Android Commands
```bash
make build-android    # Build Android APK
make run-android      # Run on device
make dev-android      # Run in debug mode
```

### Other Commands
```bash
make deps             # Install Flutter dependencies and Pods
make clean            # Clean all build caches
make test             # Run tests
make release-all      # Release build for all platforms
make help             # Show all commands
```

## Project Structure

```
remote-touch/
├── lib/                           # Flutter/Dart code (mobile common)
│   ├── main.dart                 # Main entry point
│   └── services/
│       └── ble_peripheral_manager.dart  # BLE Peripheral management
├── macos/                        # macOS-specific code
│   └── Runner/
│       ├── Services/
│       │   ├── BLECentralManager.swift      # BLE Central implementation
│       │   ├── CommandProcessor.swift       # Command processing
│       │   ├── EventGenerator.swift         # CGEvent API
│       │   └── AccessibilityManager.swift   # Permission management
│       ├── Models/
│       │   └── Command.swift               # Command model
│       ├── AppDelegate.swift
│       └── ApplicationController.swift      # Menu bar management
├── android/
│   └── app/src/main/kotlin/com/example/remote_touch/
│       └── BLEPeripheralPlugin.kt          # Android BLE Peripheral
├── Makefile                      # Build automation
└── README.md                     # This file
```

## Tech Stack

### Mobile Side (iOS/Android)
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **BLE Communication**:
  - Android: Kotlin (BluetoothGattServer, BluetoothLeAdvertiser)
  - iOS: Swift (CoreBluetooth) ※Not yet implemented
- **UI**: Material Design 3

### macOS Side
- **Framework**: Swift + AppKit
- **BLE Communication**: CoreBluetooth (CBCentralManager)
- **System Events**: CGEvent API
- **Menu Bar**: NSStatusBar

### Data Persistence
- **Android/iOS**: SharedPreferences (save and load settings)
- **Saved Settings**:
  - Touchpad sensitivity (0.5 - 3.0)
  - Control mode (BasicMouse / Presentation / MediaControl)

## Technical Details

### BLE Communication Protocol

**Service UUID**: `12345678-1234-1234-1234-123456789abc`
**Command Characteristic**: `87654321-4321-4321-4321-cba987654321`

**Command Format (JSON):**
```json
{
  "type": "mouseMove",
  "dx": -5.2,
  "dy": 10.3,
  "timestamp": 1763400392894
}
```

**Supported Command Types:**
- `mouseMove`: Cursor movement (dx, dy parameters, with sensitivity applied)
- `click`: Left click (cursor position unchanged)
- `doubleClick`: Double click (cursor position unchanged)
- `back`: Back operation (Command+←)
- `forward`: Forward operation (Command+→)
- `playPause`: Play/Pause (Media Control Mode)
- `volumeUp`: Volume up (Media Control Mode)

### Coordinate System Conversion

- **Android/iOS touch coordinates**: Top-left origin, Y-axis increases downward
- **macOS Quartz coordinates**: Top-left origin, Y-axis increases downward
- **Conversion processing**: Added as `y + dy` in EventGenerator.swift

### Thread Handling

**Android Side:**
- BLE callbacks execute on Background thread
- Flutter MethodChannel can only be called from Main thread
- Posted to Main thread with `Handler(Looper.getMainLooper())`

**macOS Side:**
- BLE callbacks execute on Main thread
- CGEvent API can be called from any thread

### Settings Persistence

**Implementation:**
- Uses `shared_preferences` package
- Settings keys managed as constants in `SettingsKeys` class
- Loaded with `_loadSettings()` on app launch
- Saved with `_saveSettings()` when returning from settings screen

**Saved Settings:**
```dart
// Touchpad sensitivity (double: 0.5 - 3.0)
'touchpad_sensitivity': 1.0

// Control mode (int: enum index)
'control_mode': 2  // 0=Presentation, 1=MediaControl, 2=BasicMouse
```

**Default Values:**
- Sensitivity: 1.0 (100%)
- Mode: BasicMouse (index: 2)

## Troubleshooting

### macOS Side

**Q: Cursor doesn't move**
- A: Check if Accessibility permission is granted
  - System Settings > Privacy & Security > Accessibility
  - Verify remote_touch is in the list and checked

**Q: Android device is not detected**
- A1: Check if Bluetooth is ON on both devices
- A2: Check if devices are nearby (communication range: about 10m)
- A3: Restart macOS app

**Q: Vertical axis movement is reversed**
- A: Check if coordinate calculation in EventGenerator.swift is correct
  - Correct: `y: currentLocation.y + clampedDelta.y`
  - Wrong: `y: currentLocation.y - clampedDelta.y`

### Android Side

**Q: Cannot connect (BLUETOOTH_ADVERTISE error)**
- A: Runtime permission required on Android 12 or later
  - Settings > Apps > RemoteTouch > Permissions
  - Allow "Nearby devices"

**Q: Commands not sent (device must not be null error)**
- A: Please update to the latest version
  - Fixed in BLEPeripheralPlugin.kt to save `connectedDevice`

**Q: Touchpad response is poor**
- A: Try hot reload (`r` key)

## Implemented Features

✅ **Touchpad Operations**
- Swipe for cursor movement
- Tap for click (no cursor movement)
- Double tap for double click (no cursor movement)
- Visual feedback on touch

✅ **Control Modes**
- Basic Mouse Mode
- Presentation Mode
- Media Control Mode

✅ **Settings Features**
- Touchpad sensitivity adjustment (0.5x - 3.0x)
- Mode selection screen
- About information
- Settings persistence (SharedPreferences)

✅ **BLE Communication**
- Android BLE Peripheral implementation
- macOS BLE Central implementation
- Auto-connect and reconnect

## Known Limitations

- **iOS version**: Not yet implemented (only Android version works)
- **Multi-display**: Only one display supported
- **Right click**: Not implemented (only left click and double click)
- **Scroll**: Not implemented (such as two-finger swipe)
- **Multiple connections**: Only 1-to-1 connection (multiple device simultaneous connection not available)
- **Media Control Mode**: playPause and volumeUp commands not implemented on macOS side

## Future Plans

- [ ] iOS version implementation
- [ ] macOS media control command support
- [ ] Right click feature (such as long press)
- [ ] Two-finger scroll
- [ ] macOS settings persistence (UserDefaults)
- [ ] Connection history saving
- [ ] Battery information display
- [ ] Multiple device management (save up to 5 Macs)

## License

This project is released under the MIT License.

## Contributing

Pull requests are welcome! We welcome contributions of any kind, including bug reports, feature requests, and code contributions.

### Documentation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[Branch Strategy](.github/BRANCH_STRATEGY.md)** - GitHub Flow details
- **[Branch Protection Setup](.github/BRANCH_PROTECTION_SETUP.md)** - Setup guide

### Quick Start

1. Fork this repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m '✨ Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

### Branch Naming Convention
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation
- `refactor/*` - Refactoring
- `test/*` - Add tests

## Developer

- **Author**: Kazuki
- **Repository**: https://github.com/Kazuki-0731/remote-touch
