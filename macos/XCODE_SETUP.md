# Xcode セットアップガイド

## 現在の状態

Flutterのビルドは成功していますが、RemoteTouchの完全な機能を有効にするには、SwiftファイルをXcodeプロジェクトに追加する必要があります。

## Xcodeプロジェクトへのファイル追加手順

1. **Xcodeワークスペースを開く**:
   ```bash
   open macos/Runner.xcworkspace
   ```

2. **ApplicationControllerと関連ファイルを追加**:
   - Xcodeで、Project Navigatorの`Runner`フォルダを右クリック
   - "Add Files to 'Runner'..."を選択
   - 以下のファイルを選択:
     - `ApplicationController.swift`
     - `PairingWindowController.swift`
   - "Copy items if needed"が**チェックされていない**ことを確認
   - "Create groups"が選択されていることを確認
   - `Runner`ターゲットがチェックされていることを確認
   - "Add"をクリック

3. **Modelsフォルダを追加**:
   - `Runner`フォルダを右クリック
   - "Add Files to 'Runner'..."を選択
   - `Models`フォルダを選択
   - "Create groups"が選択されていることを確認
   - `Runner`ターゲットがチェックされていることを確認
   - "Add"をクリック

4. **Servicesフォルダを追加**:
   - `Runner`フォルダを右クリック
   - "Add Files to 'Runner'..."を選択
   - `Services`フォルダを選択
   - "Create groups"が選択されていることを確認
   - `Runner`ターゲットがチェックされていることを確認
   - "Add"をクリック

5. **AppDelegate.swiftを復元**:
   - `macos/Runner/AppDelegate.swift`を開く
   - TODOでマークされた行のコメントを解除:
     ```swift
     @main
     class AppDelegate: FlutterAppDelegate {

       private let applicationController = ApplicationController.shared

       override func applicationDidFinishLaunching(_ notification: Notification) {
         super.applicationDidFinishLaunching(notification)
         applicationController.start()
       }

       override func applicationWillTerminate(_ notification: Notification) {
         super.applicationWillTerminate(notification)
         applicationController.stop()
       }

       override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
         // Don't quit when Flutter window closes - we're a menu bar app
         return false
       }
     }
     ```

6. **ビルドして実行**:
   - `Product > Build` (Cmd+B)を選択
   - 成功したら、`Product > Run` (Cmd+R)を選択

## 追加するファイル

### コアコントローラー
- `ApplicationController.swift` - メニューバーアプリのメインコントローラー
- `PairingWindowController.swift` - ペアリングウィンドウのUIコントローラー

### Models (Models/ フォルダ)
- `Command.swift` - コマンドデータモデル
- `Device.swift` - デバイスデータモデル
- `StatusData.swift` - ステータスデータモデル
- `AppSettings.swift` - アプリ設定モデル

### Services (Services/ フォルダ)
- `BLEPeripheralManager.swift` - BLE Peripheral実装
- `PairingManager.swift` - ペアリングロジック
- `AccessibilityManager.swift` - アクセシビリティ権限管理
- `EventGenerator.swift` - CGEventの生成
- `CommandProcessor.swift` - コマンド処理ロジック

## トラブルシューティング

### ビルドエラー: "Cannot find 'ApplicationController' in scope"
SwiftファイルがXcodeプロジェクトに追加されていません。上記の手順2-4に従ってください。

### CocoaPodsの問題
CocoaPods関連のエラーが表示される場合:
```bash
cd macos
pod install
cd ..
flutter clean
flutter pub get
```

### 権限の問題
アプリがマウスとキーボードを制御するにはアクセシビリティ権限が必要です。初回実行時にmacOSがプロンプトを表示します。
