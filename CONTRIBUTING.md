# Contributing to RemoteTouch

まず、RemoteTouchへの貢献を検討していただきありがとうございます！🎉

## 行動規範

このプロジェクトは、協力的で敬意のあるコミュニティを維持することを目指しています。参加することで、あなたは礼儀正しく、建設的にコミュニケーションすることに同意したものとみなされます。

## 貢献方法

### バグ報告

バグを見つけた場合は、以下の情報を含めてIssueを作成してください：

1. **環境情報**
   - OS（Android/iOS/macOS）とバージョン
   - Flutterバージョン
   - アプリバージョン

2. **再現手順**
   - バグを再現するための具体的な手順
   - 期待される動作
   - 実際の動作

3. **ログ/スクリーンショット**
   - エラーメッセージ
   - スクリーンショット（該当する場合）

### 機能リクエスト

新機能の提案は大歓迎です！以下を含めてIssueを作成してください：

1. **機能の説明**
   - どのような機能か
   - なぜ必要か
   - どのように使用されるか

2. **ユースケース**
   - 具体的な使用例

3. **代替案**（あれば）
   - 他に検討した方法

### コードの貢献

#### 事前準備

1. このリポジトリをフォーク
2. ローカルにクローン
3. 開発環境のセットアップ（README.mdを参照）

```bash
git clone https://github.com/YOUR_USERNAME/remote-touch.git
cd remote-touch
flutter pub get
```

#### 開発フロー

1. **新しいブランチを作成**
```bash
git checkout -b feature/your-feature-name
# または
git checkout -b fix/bug-description
```

2. **コードを書く**
   - 既存のコードスタイルに従う
   - コメントは日本語でも英語でもOK
   - 必要に応じてテストを追加

3. **コミット**
```bash
git add .
git commit -m "✨ Add new feature: your feature description"
```

**コミットメッセージの形式:**
- ✨ `:sparkles:` - 新機能
- 🐛 `:bug:` - バグ修正
- 📝 `:memo:` - ドキュメント更新
- ♻️ `:recycle:` - リファクタリング
- 🎨 `:art:` - UIの改善
- ⚡ `:zap:` - パフォーマンス改善
- 🔧 `:wrench:` - 設定変更

4. **プッシュ**
```bash
git push origin feature/your-feature-name
```

5. **Pull Requestを作成**
   - フォークしたリポジトリからPRを作成
   - 変更内容を詳しく説明
   - 関連するIssue番号を記載（`Fixes #123`など）

#### Pull Requestのガイドライン

- **1つのPRで1つの機能/修正**
- **変更内容を明確に説明**
- **テストが通ることを確認**
- **既存の機能を壊していないことを確認**

#### コードスタイル

**Dart/Flutter:**
- `flutter analyze` でwarningがないこと
- インデントは2スペース

**Swift:**
- Xcodeのデフォルトフォーマットに従う
- インデントは4スペース

**Kotlin:**
- Android Studioのデフォルトフォーマットに従う
- インデントは4スペース

## 開発環境

### 必要なツール

- Flutter 3.0+
- Xcode（macOS開発用）
- Android Studio（Android開発用）
- CocoaPods（macOS/iOS用）

### ビルドコマンド

```bash
# macOS
make install-macos

# Android
flutter run -d <device-id>

# クリーン
make clean
```

## テスト

現在、テストの実装は限定的です。テストの追加は大歓迎です！

```bash
flutter test
```

## ドキュメント

- コードにコメントを追加する際は、できるだけ「なぜ」を説明する
- 新しい機能を追加した場合は、README.mdも更新する
- 複雑なロジックには説明コメントを追加

## 質問がある場合

- Issueで質問を作成
- Discussionsで議論を開始

## ライセンス

貢献したコードは、MITライセンスの下で公開されます。

---

貢献していただき、ありがとうございます！🙏
