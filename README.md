# RemoteTouch

iPhone/AndroidをmacOSのタッチパッドとして使用できるBluetooth Low Energy (BLE)接続アプリ。

## 概要

RemoteTouchは、スマートフォンをMacのワイヤレスタッチパッドとして使用できるアプリです。Bluetooth接続により、カーソル操作、クリック、ブラウザナビゲーション（戻る/次へ）を実現します。

### アーキテクチャ

```
┌─────────────────┐          BLE          ┌─────────────────┐
│  iOS / Android  │ ────────────────────► │     macOS       │
│   (リモコン側)    │  BLE Peripheral      │   (受信側)       │
│  タッチパッド操作  │  広告・コマンド送信   │  BLE Central    │
│                 │                      │  スキャン・接続  │
└─────────────────┘                      └─────────────────┘
```

**アーキテクチャの特徴:**
- iOS/Androidアプリが**BLE Peripheral**として広告
- macOSアプリが**BLE Central**としてスキャン・接続
- iOS/Androidからコマンド（タッチパッド操作、ボタンクリックなど）をJSON形式で送信
- macOSがコマンドを受信し、CGEvent APIでシステムイベントを生成

## 主要機能

### タッチパッド操作
- **スワイプ**: カーソル移動（縦横方向に対応）
- **シングルタップ**: 左クリック
- **ダブルタップ**: ダブルクリック
- **タッチ時視覚フィードバック**: タッチ時に青い枠が光る

### ナビゲーションボタン
- **戻るボタン (◀)**: ブラウザ/Finderで「戻る」(Command+←)
- **次へボタン (▶)**: ブラウザ/Finderで「次へ」(Command+→)
- **Ripple Effect**: ボタンタップ時の視覚フィードバック

### BLE接続
- **自動広告**: Androidアプリ起動時に自動的にBLE広告開始
- **自動接続**: macOSが近くのデバイスを自動検出して接続
- **接続状態表示**: リアルタイム接続ステータス（Bluetooth アイコン）

## セットアップ

### 必要要件

- **macOS**: macOS 10.15 (Catalina) 以上
- **iOS**: iOS 15.0 以上（未実装）
- **Android**: Android 12.0 (API 31) 以上、BLE Peripheral対応デバイス
- **Flutter**: 3.0 以上
- **Bluetooth**: 両デバイスでBluetooth 4.0 (BLE) 以上をサポート

### インストール手順

#### 1. リポジトリをクローン

```bash
git clone https://github.com/Kazuki-0731/remote-touch.git
cd remote-touch
```

#### 2. 依存関係をインストール

```bash
flutter pub get
cd macos && pod install && cd ..
```

#### 3. macOSアプリをビルド・インストール

**方法1: Makefileを使用（推奨）**
```bash
make install-macos
```

このコマンドは以下を実行します：
1. リリースビルド作成
2. /Applications/remote_touch.app にインストール
3. Spotlightから起動可能に

**方法2: 手動ビルド**
```bash
flutter build macos --release
cp -R build/macos/Build/Products/Release/remote_touch.app /Applications/
```

**重要**: 初回起動時に**アクセシビリティ権限**を許可してください。
- システム設定 > プライバシーとセキュリティ > アクセシビリティ
- remote_touchアプリを許可リストに追加

#### 4. Androidアプリをビルド・実行

```bash
flutter run -d <android-device-id>
```

デバイスIDの確認:
```bash
flutter devices
```

## 使い方

### 前提条件
1. **両方のデバイスでBluetoothがONになっていること**
2. **macOS側でアクセシビリティ権限が許可されていること**
3. **iOS/AndroidとmacOSが近くにあること**（BLE通信範囲: 約10m）

### 接続手順

#### 1. macOSアプリを起動

```bash
open /Applications/remote_touch.app
```

または、Spotlightから「remote_touch」で検索

- メニューバーにRemoteTouchアイコンが表示されます
- アプリは自動的にBLEスキャンを開始します

#### 2. Androidアプリで広告を開始

1. スマートフォンでRemoteTouchアプリを起動
2. アプリが自動的にBLE広告を開始します
3. macOSアプリがスマートフォンを検出すると、自動的に接続します
4. 接続が成功すると、タッチパッド画面が表示されます

#### 3. タッチパッド操作

**画面構成:**
```
┌─────────────────────────────────┐
│ RemoteTouch          🔵 Connected│
├─────────────────────────────────┤
│                                 │
│   ┌─────────────────────────┐   │
│   │                         │   │
│   │                         │   │
│   │      タッチパッド         │   │
│   │      エリア              │   │
│   │                         │   │
│   │  (タッチ時に青く光る)     │   │
│   │                         │   │
│   └─────────────────────────┘   │
│                                 │
│   ┌──────────┐   ┌──────────┐   │
│   │  ◀ Back  │   │ Forward ▶│   │
│   └──────────┘   └──────────┘   │
└─────────────────────────────────┘
```

**操作方法:**
- **スワイプ**: タッチパッドエリアをスワイプしてカーソル移動
  - 下にスワイプ → カーソルが下に移動
  - 上にスワイプ → カーソルが上に移動
  - 横方向も同様
- **タップ**: 1回タップで左クリック
- **ダブルタップ**: 素早く2回タップでダブルクリック
- **戻るボタン**: ブラウザ/Finderで前のページに戻る
- **次へボタン**: ブラウザ/Finderで次のページに進む

## Makefileコマンド

プロジェクトにはビルド自動化のためのMakefileが含まれています：

```bash
# macOSアプリをビルドしてインストール（推奨）
make install-macos

# macOSアプリをビルドのみ
make build-macos

# macOSアプリをビルドして実行
make run-macos

# ビルドキャッシュをクリーン
make clean-macos

# Androidアプリをビルド
make build-android

# Androidアプリを実行
make run-android

# すべてのビルドキャッシュをクリーン
make clean
```

## プロジェクト構成

```
remote-touch/
├── lib/                           # Flutter/Dartコード（モバイル共通）
│   ├── main.dart                 # メインエントリーポイント
│   └── services/
│       └── ble_peripheral_manager.dart  # BLE Peripheral管理
├── macos/                        # macOS固有コード
│   └── Runner/
│       ├── Services/
│       │   ├── BLECentralManager.swift      # BLE Central実装
│       │   ├── CommandProcessor.swift       # コマンド処理
│       │   ├── EventGenerator.swift         # CGEvent API
│       │   └── AccessibilityManager.swift   # 権限管理
│       ├── Models/
│       │   └── Command.swift               # コマンドモデル
│       ├── AppDelegate.swift
│       └── ApplicationController.swift      # メニューバー管理
├── android/
│   └── app/src/main/kotlin/com/example/remote_touch/
│       └── BLEPeripheralPlugin.kt          # Android BLE Peripheral
├── Makefile                      # ビルド自動化
└── README.md                     # このファイル
```

## 技術スタック

### モバイル側（iOS/Android）
- **フレームワーク**: Flutter 3.0+
- **言語**: Dart
- **BLE通信**:
  - Android: Kotlin (BluetoothGattServer, BluetoothLeAdvertiser)
  - iOS: Swift (CoreBluetooth) ※未実装
- **UI**: Material Design 3

### macOS側
- **フレームワーク**: Swift + AppKit
- **BLE通信**: CoreBluetooth (CBCentralManager)
- **システムイベント**: CGEvent API
- **メニューバー**: NSStatusBar

## 技術的詳細

### BLE通信プロトコル

**サービスUUID**: `12345678-1234-1234-1234-123456789abc`
**コマンドCharacteristic**: `87654321-4321-4321-4321-cba987654321`

**コマンドフォーマット (JSON):**
```json
{
  "type": "mouseMove",
  "dx": -5.2,
  "dy": 10.3,
  "timestamp": 1763400392894
}
```

**サポートされるコマンドタイプ:**
- `mouseMove`: カーソル移動（dx, dy パラメータ）
- `click`: 左クリック
- `doubleClick`: ダブルクリック
- `back`: 戻る操作（Command+←）
- `forward`: 次へ操作（Command+→）

### 座標系の変換

- **Android/iOSタッチ座標**: 左上原点、Y軸は下向きに増加
- **macOS Quartz座標**: 左上原点、Y軸は下向きに増加
- **変換処理**: EventGenerator.swiftで`y + dy`として加算

### スレッド処理

**Android側:**
- BLEコールバックはBackgroundスレッドで実行
- Flutter MethodChannelはMainスレッドでのみ呼び出し可能
- `Handler(Looper.getMainLooper())`でMainスレッドに投稿

**macOS側:**
- BLEコールバックはMainスレッドで実行
- CGEvent APIはどのスレッドからでも呼び出し可能

## トラブルシューティング

### macOS側

**Q: カーソルが動かない**
- A: アクセシビリティ権限が許可されているか確認
  - システム設定 > プライバシーとセキュリティ > アクセシビリティ
  - remote_touchがリストにあり、チェックが入っているか確認

**Q: Androidデバイスが検出されない**
- A1: 両デバイスのBluetoothがONになっているか確認
- A2: デバイスが近くにあるか確認（通信範囲: 約10m）
- A3: macOSアプリを再起動

**Q: 縦軸の動きが逆になる**
- A: EventGenerator.swiftの座標計算が正しいか確認
  - 正: `y: currentLocation.y + clampedDelta.y`
  - 誤: `y: currentLocation.y - clampedDelta.y`

### Android側

**Q: 接続できない（BLUETOOTH_ADVERTISE エラー）**
- A: Android 12以降では実行時権限が必要
  - 設定 > アプリ > RemoteTouch > 権限
  - 「近くのデバイス」を許可

**Q: コマンドが送信されない（device must not be null エラー）**
- A: 最新版に更新してください
  - BLEPeripheralPlugin.ktで`connectedDevice`を保存するように修正済み

**Q: タッチパッドの反応が悪い**
- A: ホットリロード（`r`キー）を試してください

## 既知の制限事項

- **iOS版**: 未実装（Android版のみ動作）
- **マルチディスプレイ**: 1つのディスプレイのみサポート
- **右クリック**: 未実装（左クリックとダブルクリックのみ）
- **スクロール**: 未実装
- **複数接続**: 1対1接続のみ（複数デバイス同時接続不可）

## 今後の予定

- [ ] iOS版の実装
- [ ] 右クリック機能
- [ ] 2本指スクロール
- [ ] カーソル速度調整設定
- [ ] 接続履歴の保存
- [ ] バッテリー情報の表示

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

プルリクエストを歓迎します。大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## 開発者

- **Author**: Kazuki
- **Repository**: https://github.com/Kazuki-0731/remote-touch
