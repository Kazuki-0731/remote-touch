# Requirements Document

## Introduction

RemoteTouchは、iPhoneをmacOSデバイスのリモートコントローラーとして使用できるBluetooth Low Energy (BLE)接続アプリケーションです。ユーザーはiPhoneのタッチスクリーンを使用してMacのカーソルを操作し、プレゼンテーション、メディア再生、一般的なマウス操作を離れた場所から実行できます。

## Glossary

- **iOS App**: iPhoneで動作するSwift/SwiftUIベースのクライアントアプリケーション
- **macOS App**: Mac上で動作するSwift/AppKitベースのサーバーアプリケーション
- **BLE Connection**: Bluetooth Low Energyを使用したiOSとmacOS間の通信チャネル
- **Touchpad Area**: iOS App上のカーソル移動用タッチ操作エリア
- **Control Mode**: プレゼンテーション、メディア、基本マウスの3つの操作モード
- **Pairing Code**: デバイスペアリング時に使用されるワンタイム認証コード
- **CGEvent API**: macOSでマウスとキーボードイベントを生成するシステムAPI

## Requirements

### Requirement 1

**User Story:** ユーザーとして、iPhoneのタッチパッドエリアをスワイプしてMacのカーソルを移動させたい。これにより、離れた場所からMacを操作できる。

#### Acceptance Criteria

1. WHEN ユーザーがTouchpad Area上で指をスワイプする, THE iOS App SHALL スワイプの方向と距離をBLE Connection経由でmacOS Appに送信する
2. WHEN macOS AppがBLE Connection経由でスワイプデータを受信する, THE macOS App SHALL CGEvent APIを使用してカーソルを対応する方向と距離に移動させる
3. WHILE ユーザーがTouchpad Area上で連続的にスワイプしている, THE iOS App SHALL 16ミリ秒以内の間隔でスワイプデータを送信する
4. THE iOS App SHALL スワイプ速度に基づいてカーソル移動速度を0.5倍から3.0倍の範囲で調整する

### Requirement 2

**User Story:** ユーザーとして、タッチパッドエリアでタップ操作を行いたい。これにより、Macでクリック操作を実行できる。

#### Acceptance Criteria

1. WHEN ユーザーがTouchpad Area上でシングルタップを実行する, THE iOS App SHALL クリックコマンドをBLE Connection経由でmacOS Appに送信する
2. WHEN macOS AppがBLE Connection経由でクリックコマンドを受信する, THE macOS App SHALL CGEvent APIを使用して左クリックイベントを生成する
3. WHEN ユーザーがTouchpad Area上で300ミリ秒以内にダブルタップを実行する, THE iOS App SHALL ダブルクリックコマンドをBLE Connection経由でmacOS Appに送信する
4. WHEN macOS AppがBLE Connection経由でダブルクリックコマンドを受信する, THE macOS App SHALL CGEvent APIを使用してダブルクリックイベントを生成する

### Requirement 3

**User Story:** ユーザーとして、物理ボタンを使用して戻る操作と決定操作を実行したい。これにより、プレゼンテーションやブラウジング時に素早く操作できる。

#### Acceptance Criteria

1. WHEN ユーザーが←ボタンをタップする, THE iOS App SHALL 現在のControl Modeに応じた戻るコマンドをBLE Connection経由でmacOS Appに送信する
2. WHEN ユーザーが→ボタンをタップする, THE iOS App SHALL 現在のControl Modeに応じた決定コマンドをBLE Connection経由でmacOS Appに送信する
3. WHEN macOS Appがプレゼンテーションモードで戻るコマンドを受信する, THE macOS App SHALL CGEvent APIを使用して左矢印キーイベントを生成する
4. WHEN macOS Appがプレゼンテーションモードで決定コマンドを受信する, THE macOS App SHALL CGEvent APIを使用して右矢印キーイベントを生成する
5. WHEN macOS Appが基本マウスモードで戻るコマンドを受信する, THE macOS App SHALL CGEvent APIを使用してCommand+左矢印キーイベントを生成する
6. WHEN macOS Appが基本マウスモードで決定コマンドを受信する, THE macOS App SHALL CGEvent APIを使用してEnterキーイベントを生成する

### Requirement 4

**User Story:** ユーザーとして、iPhoneとMacをBluetooth経由でペアリングしたい。これにより、安全な接続を確立できる。

#### Acceptance Criteria

1. WHEN ユーザーがiOS App上でデバイススキャンを開始する, THE iOS App SHALL BLE Connectionを使用して範囲内のmacOS Appを検出する
2. WHEN macOS AppがBLE Connection経由でペアリングリクエストを受信する, THE macOS App SHALL 6桁のPairing Codeを生成して画面に表示する
3. WHEN ユーザーがiOS AppにPairing Codeを入力する, THE iOS App SHALL Pairing CodeをBLE Connection経由でmacOS Appに送信する
4. WHEN macOS AppがBLE Connection経由で正しいPairing Codeを受信する, THE macOS App SHALL ペアリングを確立してデバイス情報を保存する
5. IF macOS AppがBLE Connection経由で誤ったPairing Codeを受信する, THEN THE macOS App SHALL ペアリングを拒否してエラーメッセージを返す

### Requirement 5

**User Story:** ユーザーとして、接続状態とバッテリー情報をリアルタイムで確認したい。これにより、接続の安定性を把握できる。

#### Acceptance Criteria

1. WHILE BLE Connectionが確立されている, THE iOS App SHALL 接続状態を「接続済み」として画面に表示する
2. WHILE BLE Connectionが切断されている, THE iOS App SHALL 接続状態を「切断」として画面に表示する
3. WHEN BLE Connectionが確立される, THE macOS App SHALL 2秒ごとにバッテリーレベルをBLE Connection経由でiOS Appに送信する
4. WHEN iOS AppがBLE Connection経由でバッテリーレベルを受信する, THE iOS App SHALL バッテリーレベルを画面に表示する

### Requirement 6

**User Story:** ユーザーとして、複数のMacデバイスを登録して切り替えたい。これにより、複数のMacを1つのiPhoneで操作できる。

#### Acceptance Criteria

1. THE iOS App SHALL 最大5台のmacOSデバイス情報を永続的に保存する
2. WHEN ユーザーがデバイス選択画面で登録済みデバイスを選択する, THE iOS App SHALL 選択されたデバイスへのBLE Connectionを確立する
3. WHEN ユーザーが新しいデバイスを追加する, THE iOS App SHALL デバイス情報をローカルストレージに保存する
4. WHEN 登録済みデバイスが5台に達している状態でユーザーが新しいデバイスを追加する, THE iOS App SHALL 最も古いデバイスを削除して新しいデバイスを追加する

### Requirement 7

**User Story:** ユーザーとして、プレゼンテーション、メディア、基本マウスの3つのモードを切り替えたい。これにより、用途に応じた最適な操作ができる。

#### Acceptance Criteria

1. WHEN ユーザーがモード選択画面でプレゼンテーションモードを選択する, THE iOS App SHALL Control Modeをプレゼンテーションモードに設定する
2. WHEN ユーザーがモード選択画面でメディアコントロールモードを選択する, THE iOS App SHALL Control Modeをメディアコントロールモードに設定する
3. WHEN ユーザーがモード選択画面で基本マウスモードを選択する, THE iOS App SHALL Control Modeを基本マウスモードに設定する
4. WHEN Control Modeが変更される, THE iOS App SHALL 新しいモードをBLE Connection経由でmacOS Appに送信する
5. WHEN macOS AppがBLE Connection経由でモード変更を受信する, THE macOS App SHALL 受信したモードに応じてコマンド解釈を変更する

### Requirement 8

**User Story:** ユーザーとして、タッチパッドの感度を調整したい。これにより、自分の操作スタイルに合わせた快適な操作ができる。

#### Acceptance Criteria

1. THE iOS App SHALL タッチパッド感度を0.5倍から3.0倍の範囲で0.1倍刻みで設定できる
2. WHEN ユーザーが設定画面で感度を変更する, THE iOS App SHALL 新しい感度設定をローカルストレージに保存する
3. WHEN iOS Appが起動する, THE iOS App SHALL ローカルストレージから感度設定を読み込む
4. WHEN ユーザーがTouchpad Area上でスワイプする, THE iOS App SHALL 保存された感度設定を適用してカーソル移動距離を計算する

### Requirement 9

**User Story:** ユーザーとして、メディアコントロールモードで再生/一時停止と音量調整を実行したい。これにより、離れた場所からメディア再生を制御できる。

#### Acceptance Criteria

1. WHERE Control Modeがメディアコントロールモードである, WHEN ユーザーがTouchpad Area上でシングルタップを実行する, THE iOS App SHALL 再生/一時停止コマンドをBLE Connection経由でmacOS Appに送信する
2. WHERE Control Modeがメディアコントロールモードである, WHEN ユーザーがTouchpad Area上で上方向にスワイプする, THE iOS App SHALL 音量アップコマンドをBLE Connection経由でmacOS Appに送信する
3. WHERE Control Modeがメディアコントロールモードである, WHEN ユーザーがTouchpad Area上で下方向にスワイプする, THE iOS App SHALL 音量ダウンコマンドをBLE Connection経由でmacOS Appに送信する
4. WHEN macOS AppがBLE Connection経由で再生/一時停止コマンドを受信する, THE macOS App SHALL CGEvent APIを使用してメディア再生/一時停止キーイベントを生成する
5. WHEN macOS AppがBLE Connection経由で音量コマンドを受信する, THE macOS App SHALL CGEvent APIを使用して対応する音量調整キーイベントを生成する

### Requirement 10

**User Story:** ユーザーとして、macOS側でアクセシビリティ権限を適切に設定したい。これにより、アプリがカーソルとキーボードを制御できる。

#### Acceptance Criteria

1. WHEN macOS Appが初回起動する, THE macOS App SHALL アクセシビリティ権限の状態を確認する
2. IF アクセシビリティ権限が付与されていない, THEN THE macOS App SHALL ユーザーにシステム環境設定を開くよう促すダイアログを表示する
3. WHILE アクセシビリティ権限が付与されていない, THE macOS App SHALL CGEvent APIを使用したイベント生成を実行しない
4. WHEN アクセシビリティ権限が付与される, THE macOS App SHALL CGEvent APIを使用したイベント生成を有効化する

### Requirement 11

**User Story:** ユーザーとして、アイドル時にアプリが自動的にスリープして電力を節約したい。これにより、バッテリー消費を抑えられる。

#### Acceptance Criteria

1. WHEN ユーザーが60秒間iOS Appを操作しない, THE iOS App SHALL アイドル状態に遷移する
2. WHILE iOS Appがアイドル状態である, THE iOS App SHALL BLE Connectionのデータ送信頻度を10秒に1回に削減する
3. WHEN ユーザーがiOS Appを再度操作する, THE iOS App SHALL アイドル状態から通常状態に復帰する
4. WHEN iOS Appが通常状態に復帰する, THE iOS App SHALL BLE Connectionのデータ送信頻度を通常の頻度に戻す

### Requirement 12

**User Story:** ユーザーとして、BLE接続が切断された場合に自動的に再接続したい。これにより、手動で再接続する手間を省ける。

#### Acceptance Criteria

1. WHEN BLE Connectionが予期せず切断される, THE iOS App SHALL 接続状態を「再接続中」として画面に表示する
2. WHEN BLE Connectionが切断される, THE iOS App SHALL 5秒ごとに最大10回まで再接続を試行する
3. WHEN 再接続試行が成功する, THE iOS App SHALL 接続状態を「接続済み」として画面に表示する
4. IF 10回の再接続試行が全て失敗する, THEN THE iOS App SHALL 接続状態を「切断」として画面に表示してユーザーに手動再接続を促す
