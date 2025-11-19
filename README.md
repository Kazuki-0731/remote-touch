# RemoteTouch

![CI/CD](https://github.com/Kazuki-0731/remote-touch/actions/workflows/flutter-ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS-lightgrey.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart)
![Swift](https://img.shields.io/badge/Swift-5.0%2B-FA7343?logo=swift)
![Kotlin](https://img.shields.io/badge/Kotlin-1.9%2B-7F52FF?logo=kotlin)

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
- **シングルタップ**: 左クリック（カーソル位置そのまま）
- **ダブルタップ**: ダブルクリック（カーソル位置そのまま）
- **タッチ時視覚フィードバック**: タッチ時に青い枠が光る
- **感度調整**: 0.5倍〜3.0倍まで調整可能

### コントロールモード
3つのモードを切り替え可能：

1. **Basic Mouse Mode（基本マウスモード）**
   - 標準的なマウス操作
   - Back/Forward ボタン

2. **Presentation Mode（プレゼンモード）**
   - プレゼンテーション操作に最適化
   - Previous/Next スライドボタン

3. **Media Control Mode（メディアコントロールモード）**
   - メディア再生操作
   - Play/Pause, Volume ボタン

### モード別ボタン配置
- **Basic Mouse Mode**: Back (◀) / Forward (▶)
- **Presentation Mode**: Previous (◀) / Next (▶)
- **Media Control Mode**: Play/Pause (▶) / Volume (🔊)
- **Ripple Effect**: ボタンタップ時の視覚フィードバック

### 設定画面
- **Control Mode**: モード選択画面へのナビゲーション
- **Touchpad Sensitivity**: スライダーで感度調整（0.5x - 3.0x）
- **About**: アプリ情報表示
- **設定の永続化**: SharedPreferencesで設定を自動保存・復元

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
│ RemoteTouch   🔵 Connected    ⚙️│
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

**基本操作:**
- **スワイプ**: タッチパッドエリアをスワイプしてカーソル移動
  - 下にスワイプ → カーソルが下に移動
  - 上にスワイプ → カーソルが上に移動
  - 横方向も同様
- **タップ**: 1回タップで左クリック（カーソルは移動しない）
- **ダブルタップ**: 素早く2回タップでダブルクリック（カーソルは移動しない）

**設定画面:**
- AppBar右上の⚙️アイコンをタップ
- **Control Mode**: モード選択（Basic Mouse / Presentation / Media Control）
  - タップして3つのモードから選択
  - 選択したモードは自動的に保存される
- **Touchpad Sensitivity**: 感度調整（50% - 300%）
  - スライダーをドラッグして調整
  - 調整した感度は自動的に保存される
- **About**: アプリ情報
- **設定の保存**: 戻るボタンで戻ると自動的に保存され、次回起動時に復元される

**モード別ボタン:**
- **Basic Mouse Mode**:
  - Back (◀): ブラウザ/Finderで戻る（Command+←）
  - Forward (▶): ブラウザ/Finderで次へ（Command+→）
- **Presentation Mode**:
  - Previous (◀): 前のスライド（Command+←）
  - Next (▶): 次のスライド（Command+→）
- **Media Control Mode**:
  - Play/Pause (▶): 再生/一時停止
  - Volume (🔊): 音量アップ

## Makefileコマンド

プロジェクトにはビルド自動化のためのMakefileが含まれています：

### macOSコマンド
```bash
make install-macos    # ビルドして/Applicationsにインストール（推奨）
make build-macos      # リリースビルドのみ
make run-macos        # インストール済みアプリを起動
make clean-macos      # macOSビルドをクリーン
make dev-macos        # デバッグモードで実行
```

### iOSコマンド
```bash
make build-ios        # iOSリリースビルド
make run-ios          # デバイス/シミュレータで実行
make clean-ios        # iOSビルドとPodsをクリーン
make dev-ios          # デバッグモードで実行
```

### Androidコマンド
```bash
make build-android    # Android APKビルド
make run-android      # デバイスで実行
make dev-android      # デバッグモードで実行
```

### その他のコマンド
```bash
make deps             # Flutter依存関係とPodsをインストール
make clean            # すべてのビルドキャッシュをクリーン
make test             # テスト実行
make release-all      # すべてのプラットフォームをリリースビルド
make help             # すべてのコマンドを表示
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

### データ永続化
- **Android/iOS**: SharedPreferences（設定の保存・読み込み）
- **保存される設定**:
  - タッチパッド感度（0.5 - 3.0）
  - コントロールモード（BasicMouse / Presentation / MediaControl）

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
- `mouseMove`: カーソル移動（dx, dy パラメータ、感度適用済み）
- `click`: 左クリック（カーソル位置そのまま）
- `doubleClick`: ダブルクリック（カーソル位置そのまま）
- `back`: 戻る操作（Command+←）
- `forward`: 次へ操作（Command+→）
- `playPause`: 再生/一時停止（Media Control Mode）
- `volumeUp`: 音量アップ（Media Control Mode）

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

### 設定の永続化

**実装方法:**
- `shared_preferences` パッケージを使用
- 設定キーは `SettingsKeys` クラスで定数管理
- アプリ起動時に `_loadSettings()` で読み込み
- 設定画面から戻る時に `_saveSettings()` で保存

**保存される設定:**
```dart
// タッチパッド感度（double: 0.5 - 3.0）
'touchpad_sensitivity': 1.0

// コントロールモード（int: enum index）
'control_mode': 2  // 0=Presentation, 1=MediaControl, 2=BasicMouse
```

**デフォルト値:**
- 感度: 1.0（100%）
- モード: BasicMouse（index: 2）

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

## 実装済み機能

✅ **タッチパッド操作**
- スワイプでカーソル移動
- タップでクリック（カーソル移動なし）
- ダブルタップでダブルクリック（カーソル移動なし）
- タッチ時の視覚フィードバック

✅ **コントロールモード**
- Basic Mouse Mode
- Presentation Mode
- Media Control Mode

✅ **設定機能**
- タッチパッド感度調整（0.5x - 3.0x）
- モード選択画面
- About情報
- 設定の永続化（SharedPreferences）

✅ **BLE通信**
- Android BLE Peripheral実装
- macOS BLE Central実装
- 自動接続・再接続

## 既知の制限事項

- **iOS版**: 未実装（Android版のみ動作）
- **マルチディスプレイ**: 1つのディスプレイのみサポート
- **右クリック**: 未実装（左クリックとダブルクリックのみ）
- **スクロール**: 未実装（2本指スワイプなど）
- **複数接続**: 1対1接続のみ（複数デバイス同時接続不可）
- **Media Control Mode**: playPauseとvolumeUpコマンドはmacOS側未実装

## 今後の予定

- [ ] iOS版の実装
- [ ] macOS側でメディアコントロールコマンド対応
- [ ] 右クリック機能（長押しなど）
- [ ] 2本指スクロール
- [ ] macOS側の設定永続化（UserDefaults）
- [ ] 接続履歴の保存
- [ ] バッテリー情報の表示
- [ ] 複数デバイス管理（最大5台のMacを保存）

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

プルリクエストを歓迎します！バグ報告、機能リクエスト、コードの貢献など、どんな形でも貢献をお待ちしています。

詳細は [CONTRIBUTING.md](CONTRIBUTING.md) をご覧ください。

### クイックスタート

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m '✨ Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. Pull Requestを作成

## 開発者

- **Author**: Kazuki
- **Repository**: https://github.com/Kazuki-0731/remote-touch
