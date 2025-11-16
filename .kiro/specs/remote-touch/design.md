# Design Document

## Overview

RemoteTouchは、iOS（iPhone）とmacOSの2つのアプリケーションで構成されるクライアント・サーバーシステムです。Bluetooth Low Energy (BLE)を通信プロトコルとして使用し、iPhoneからMacのカーソルとキーボードをリモート制御します。

システムは以下の主要コンポーネントで構成されます：
- **iOS App**: SwiftUIベースのクライアントアプリケーション（タッチ入力の検出と送信）
- **macOS App**: AppKitベースのサーバーアプリケーション（BLEサーバーとシステムイベント生成）
- **BLE Protocol**: カスタムGATTサービスを使用した双方向通信

## Architecture

### System Architecture

```
┌─────────────────────────────────────┐
│         iOS App (iPhone)            │
│  ┌──────────────────────────────┐   │
│  │   SwiftUI Views              │   │
│  │  - TouchpadView              │   │
│  │  - DeviceListView            │   │
│  │  - SettingsView              │   │
│  └──────────┬───────────────────┘   │
│             │                        │
│  ┌──────────▼───────────────────┐   │
│  │   ViewModels                 │   │
│  │  - TouchpadViewModel         │   │
│  │  - ConnectionViewModel       │   │
│  └──────────┬───────────────────┘   │
│             │                        │
│  ┌──────────▼───────────────────┐   │
│  │   Services                   │   │
│  │  - BLECentralManager         │   │
│  │  - GestureProcessor          │   │
│  │  - DeviceStorage             │   │
│  └──────────┬───────────────────┘   │
│             │ Core Bluetooth         │
└─────────────┼────────────────────────┘
              │ BLE Connection
┌─────────────▼────────────────────────┐
│         macOS App (Mac)              │
│  ┌──────────────────────────────┐   │
│  │   Services                   │   │
│  │  - BLEPeripheralManager      │   │
│  │  - CommandProcessor          │   │
│  │  - EventGenerator            │   │
│  └──────────┬───────────────────┘   │
│             │                        │
│  ┌──────────▼───────────────────┐   │
│  │   System Integration         │   │
│  │  - CGEvent API               │   │
│  │  - Accessibility Check       │   │
│  └──────────────────────────────┘   │
└──────────────────────────────────────┘
```

### iOS App Architecture (MVVM Pattern)

```
Views (SwiftUI)
    ↓
ViewModels (ObservableObject)
    ↓
Services (Business Logic)
    ↓
Core Bluetooth / UserDefaults
```

### macOS App Architecture (Service-Based)

```
BLE Peripheral Manager
    ↓
Command Processor
    ↓
Event Generator (CGEvent API)
    ↓
macOS System
```

## Components and Interfaces

### iOS App Components

#### 1. Views (SwiftUI)

**TouchpadView**
- タッチパッドエリアの表示と操作検出
- 物理ボタン（←/→）の表示
- 接続状態の表示

```swift
struct TouchpadView: View {
    @StateObject var viewModel: TouchpadViewModel
    
    var body: some View {
        VStack {
            // Touchpad area
            TouchpadAreaView(viewModel: viewModel)
            
            // Control buttons
            HStack {
                Button("←") { viewModel.sendBackCommand() }
                Button("→") { viewModel.sendForwardCommand() }
            }
            
            // Connection status
            ConnectionStatusView(viewModel: viewModel.connectionViewModel)
        }
    }
}
```

**DeviceListView**
- 利用可能なMacデバイスのリスト表示
- デバイススキャン機能
- ペアリングコード入力UI

**ModeSelectionView**
- 3つの操作モード選択UI
- 現在のモード表示

**SettingsView**
- 感度調整スライダー
- 登録済みデバイス管理

#### 2. ViewModels

**TouchpadViewModel**
```swift
class TouchpadViewModel: ObservableObject {
    @Published var currentMode: ControlMode = .basicMouse
    @Published var sensitivity: Double = 1.0
    
    private let gestureProcessor: GestureProcessor
    private let bleManager: BLECentralManager
    
    func handleSwipe(translation: CGSize, velocity: CGSize)
    func handleTap(count: Int)
    func handlePinch(scale: CGFloat)
    func sendBackCommand()
    func sendForwardCommand()
}
```

**ConnectionViewModel**
```swift
class ConnectionViewModel: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var connectedDevice: Device?
    @Published var batteryLevel: Int = 100
    
    private let bleManager: BLECentralManager
    
    func scanForDevices()
    func connect(to device: Device)
    func disconnect()
    func retryConnection()
}
```

#### 3. Services

**BLECentralManager**
```swift
class BLECentralManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    // GATT Service UUIDs
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    static let commandCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    static let statusCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")
    
    func startScanning()
    func stopScanning()
    func connect(to peripheral: CBPeripheral)
    func disconnect()
    func sendCommand(_ command: Command)
}
```

**GestureProcessor**
```swift
class GestureProcessor {
    private var sensitivity: Double
    private var lastSwipeTime: Date?
    
    func processSwipe(translation: CGSize, velocity: CGSize) -> CursorMovement
    func processTap(count: Int, location: CGPoint) -> TapCommand
    func processPinch(scale: CGFloat) -> PinchCommand
    
    private func calculateCursorDelta(translation: CGSize, velocity: CGSize) -> CGPoint
}
```

**DeviceStorage**
```swift
class DeviceStorage {
    private let maxDevices = 5
    private let userDefaults = UserDefaults.standard
    
    func saveDevice(_ device: Device)
    func loadDevices() -> [Device]
    func removeDevice(_ device: Device)
    func updateDevice(_ device: Device)
}
```

### macOS App Components

#### 1. BLEPeripheralManager

```swift
class BLEPeripheralManager: NSObject {
    private var peripheralManager: CBPeripheralManager!
    private var commandCharacteristic: CBMutableCharacteristic!
    private var statusCharacteristic: CBMutableCharacteristic!
    
    func startAdvertising()
    func stopAdvertising()
    func sendStatus(_ status: StatusData)
    
    // Delegate methods
    func peripheralManager(_ peripheral: CBPeripheralManager, 
                          didReceiveWrite requests: [CBATTRequest])
}
```

#### 2. CommandProcessor

```swift
class CommandProcessor {
    private var currentMode: ControlMode = .basicMouse
    private let eventGenerator: EventGenerator
    
    func processCommand(_ command: Command) {
        switch command {
        case .cursorMove(let delta):
            eventGenerator.moveCursor(by: delta)
        case .tap(let type):
            eventGenerator.generateClick(type: type)
        case .button(let action):
            handleButtonAction(action)
        case .modeChange(let mode):
            currentMode = mode
        }
    }
    
    private func handleButtonAction(_ action: ButtonAction) {
        switch (action, currentMode) {
        case (.back, .presentation):
            eventGenerator.generateKeyPress(.leftArrow)
        case (.forward, .presentation):
            eventGenerator.generateKeyPress(.rightArrow)
        case (.back, .basicMouse):
            eventGenerator.generateKeyPress(.leftArrow, modifiers: .command)
        case (.forward, .basicMouse):
            eventGenerator.generateKeyPress(.return)
        // ... other cases
        }
    }
}
```

#### 3. EventGenerator

```swift
class EventGenerator {
    func moveCursor(by delta: CGPoint) {
        guard checkAccessibilityPermission() else { return }
        
        let currentLocation = NSEvent.mouseLocation
        let newLocation = CGPoint(
            x: currentLocation.x + delta.x,
            y: currentLocation.y + delta.y
        )
        
        let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: newLocation,
            mouseButton: .left
        )
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func generateClick(type: ClickType) {
        guard checkAccessibilityPermission() else { return }
        
        let location = NSEvent.mouseLocation
        
        switch type {
        case .single:
            postMouseEvent(.leftMouseDown, at: location)
            postMouseEvent(.leftMouseUp, at: location)
        case .double:
            postMouseEvent(.leftMouseDown, at: location)
            postMouseEvent(.leftMouseUp, at: location)
            postMouseEvent(.leftMouseDown, at: location)
            postMouseEvent(.leftMouseUp, at: location)
        }
    }
    
    func generateKeyPress(_ key: KeyCode, modifiers: CGEventFlags = []) {
        guard checkAccessibilityPermission() else { return }
        
        let keyDownEvent = CGEvent(
            keyboardEventSource: nil,
            virtualKey: key.rawValue,
            keyDown: true
        )
        keyDownEvent?.flags = modifiers
        keyDownEvent?.post(tap: .cghidEventTap)
        
        let keyUpEvent = CGEvent(
            keyboardEventSource: nil,
            virtualKey: key.rawValue,
            keyDown: false
        )
        keyUpEvent?.post(tap: .cghidEventTap)
    }
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
}
```

#### 4. AccessibilityManager

```swift
class AccessibilityManager {
    func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func openSystemPreferences() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
```

## Data Models

### Command Protocol (BLE Communication)

```swift
enum Command: Codable {
    case cursorMove(delta: CGPoint)
    case tap(type: ClickType)
    case button(action: ButtonAction)
    case modeChange(mode: ControlMode)
    case mediaControl(action: MediaAction)
    case pinch(scale: CGFloat)
}

enum ClickType: String, Codable {
    case single
    case double
}

enum ButtonAction: String, Codable {
    case back
    case forward
}

enum ControlMode: String, Codable {
    case presentation
    case mediaControl
    case basicMouse
}

enum MediaAction: String, Codable {
    case playPause
    case volumeUp
    case volumeDown
}
```

### Status Protocol (BLE Communication)

```swift
struct StatusData: Codable {
    let batteryLevel: Int
    let timestamp: Date
    let connectionQuality: Int // 0-100
}
```

### Device Model

```swift
struct Device: Codable, Identifiable {
    let id: UUID
    let name: String
    let peripheralUUID: UUID
    var lastConnected: Date
    var isPaired: Bool
}
```

### Settings Model

```swift
struct AppSettings: Codable {
    var sensitivity: Double = 1.0
    var idleTimeout: TimeInterval = 60.0
    var autoReconnect: Bool = true
    var maxReconnectAttempts: Int = 10
}
```

## BLE Protocol Specification

### GATT Service Structure

**Primary Service**: RemoteTouch Control Service
- UUID: `12345678-1234-1234-1234-123456789ABC`

**Characteristics**:

1. **Command Characteristic** (Write)
   - UUID: `12345678-1234-1234-1234-123456789ABD`
   - Properties: Write
   - Description: iOS → macOS commands
   - Data Format: JSON-encoded Command enum

2. **Status Characteristic** (Notify)
   - UUID: `12345678-1234-1234-1234-123456789ABE`
   - Properties: Notify
   - Description: macOS → iOS status updates
   - Data Format: JSON-encoded StatusData

3. **Pairing Characteristic** (Write, Read)
   - UUID: `12345678-1234-1234-1234-123456789ABF`
   - Properties: Write, Read
   - Description: Pairing code exchange
   - Data Format: 6-digit string

### Communication Flow

#### Pairing Flow
```
iOS                          macOS
 |                             |
 |-- Scan for devices -------->|
 |<-- Advertisement ---------- |
 |                             |
 |-- Connect ----------------->|
 |<-- Connected -------------- |
 |                             |
 |-- Request pairing --------->|
 |                             | (Generate 6-digit code)
 |                             | (Display on screen)
 |<-- Pairing required ------- |
 |                             |
 | (User enters code)          |
 |-- Send pairing code ------->|
 |                             | (Verify code)
 |<-- Pairing success -------- |
```

#### Normal Operation Flow
```
iOS                          macOS
 |                             |
 |-- Cursor move command ----->|
 |                             | (Move cursor via CGEvent)
 |<-- Status update ---------- |
 |                             |
 |-- Tap command ------------->|
 |                             | (Generate click via CGEvent)
 |<-- Status update ---------- |
```

## Error Handling

### iOS App Error Scenarios

1. **BLE Connection Failure**
   - Retry logic: 5秒間隔で最大10回
   - User notification: 接続状態表示の更新
   - Fallback: 手動再接続の促し

2. **Pairing Failure**
   - Invalid code: エラーメッセージ表示、再入力促し
   - Timeout: 60秒後に自動キャンセル
   - User action: ペアリングプロセスの再開

3. **Command Send Failure**
   - Retry: 即座に1回リトライ
   - Logging: 失敗したコマンドをログに記録
   - User feedback: なし（透過的に処理）

4. **Device Storage Error**
   - Fallback: メモリ内のみで動作
   - User notification: 設定保存失敗の通知

### macOS App Error Scenarios

1. **Accessibility Permission Denied**
   - Detection: 起動時とコマンド実行時
   - User action: システム環境設定を開くダイアログ表示
   - Behavior: 権限付与まで機能を無効化

2. **BLE Advertising Failure**
   - Retry: 10秒後に再試行
   - Logging: エラーログの記録
   - User notification: メニューバーアイコンで状態表示

3. **CGEvent Generation Failure**
   - Logging: 失敗したイベントをログに記録
   - Fallback: なし（権限問題の可能性を示唆）

4. **Invalid Command Received**
   - Validation: JSON decode失敗時
   - Logging: 不正なコマンドをログに記録
   - Response: エラーステータスを返送

## Testing Strategy

### Unit Testing

**iOS App**
- `GestureProcessor`: スワイプ/タップ/ピンチの計算ロジック
- `DeviceStorage`: デバイスの保存/読み込み/削除
- `Command` encoding/decoding: JSON シリアライゼーション

**macOS App**
- `CommandProcessor`: コマンドの解釈とモード別処理
- `StatusData` encoding/decoding: JSON シリアライゼーション

### Integration Testing

**BLE Communication**
- iOS → macOS コマンド送信
- macOS → iOS ステータス通知
- ペアリングフロー

**System Integration**
- CGEvent API呼び出し（手動テスト）
- アクセシビリティ権限チェック

### Manual Testing Scenarios

1. **基本操作テスト**
   - タッチパッドでカーソル移動
   - タップでクリック
   - ダブルタップでダブルクリック
   - 物理ボタンの動作確認

2. **モード切り替えテスト**
   - プレゼンテーションモード: スライド操作
   - メディアモード: 再生/音量調整
   - 基本マウスモード: 標準操作

3. **接続テスト**
   - ペアリング
   - 自動再接続
   - 複数デバイス切り替え

4. **エッジケーステスト**
   - 範囲外移動（接続切断）
   - バックグラウンド遷移
   - 低バッテリー状態

## Performance Considerations

### Latency Optimization
- BLE通信: 16ms以内のコマンド送信間隔
- イベント生成: CGEvent APIの即座実行
- UI更新: SwiftUIの自動最適化に依存

### Battery Optimization
- アイドル検出: 60秒無操作でスリープ
- BLE通信削減: アイドル時は10秒間隔
- バックグラウンド処理: 最小限に抑制

### Memory Management
- デバイスリスト: 最大5台に制限
- コマンドキュー: 不要（即座送信）
- ログ: ローテーション機能（最大1MB）

## Security Considerations

### Pairing Security
- ワンタイムコード: 6桁の数字（1,000,000通り）
- タイムアウト: 60秒で無効化
- 再試行制限: 3回失敗でロックアウト（5分間）

### Communication Security
- BLE暗号化: iOS/macOSの標準BLE暗号化に依存
- コマンド検証: JSON decode失敗時は無視
- 認証済みデバイスのみ: ペアリング済みデバイスのみ接続許可

### Privacy
- デバイス情報: ローカルストレージのみ（外部送信なし）
- ログ: 個人情報を含まない
- 権限: 必要最小限（Bluetooth、アクセシビリティ）

## Deployment Considerations

### iOS App
- Minimum iOS version: iOS 15.0
- Required capabilities: Bluetooth
- App Store submission: プライバシーポリシー必須

### macOS App
- Minimum macOS version: macOS 12.0 (Monterey)
- Required permissions: Bluetooth、アクセシビリティ
- Distribution: Mac App Store または Direct Download
- Notarization: 必須（macOS Catalina以降）

### First-Time Setup Flow

1. **iOS App初回起動**
   - Bluetooth権限リクエスト
   - チュートリアル表示（オプション）

2. **macOS App初回起動**
   - アクセシビリティ権限リクエスト
   - メニューバーアイコン表示
   - BLEアドバタイジング開始

3. **ペアリング**
   - iOS: デバイススキャン
   - macOS: ペアリングコード表示
   - iOS: コード入力
   - 接続確立

## Future Enhancements

- 2本指スワイプでスクロール
- 3本指ジェスチャーでMission Control
- カスタムボタンマッピング
- マルチタッチジェスチャーの拡張
- Haptic Feedbackの追加
- Apple Watchサポート
