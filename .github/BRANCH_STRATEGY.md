# ブランチ戦略：GitHub Flow

RemoteTouchプロジェクトは**GitHub Flow**を採用しています。

## 概要

```
main (常にビルド可能、リリース可能)
  ↓
feature/xxx (新機能)
fix/xxx (バグ修正)
docs/xxx (ドキュメント)
  ↓
Pull Request → レビュー → マージ
  ↓
自動デプロイ (CI/CD)
```

## ブランチ

### main ブランチ
- 常にビルド可能な状態を保つ
- 直接コミット禁止（PR経由のみ）
- CI/CDが必ず成功している状態
- このブランチから直接リリース

### 作業ブランチ
機能開発やバグ修正は、必ず新しいブランチを作成してください。

## ブランチ命名規則

### 機能追加
```bash
feature/機能名
feature/add-right-click
feature/scroll-support
feature/ios-ble-peripheral
```

### バグ修正
```bash
fix/バグ内容
fix/cursor-offset
fix/connection-timeout
fix/double-tap-delay
```

### ドキュメント
```bash
docs/内容
docs/update-readme
docs/add-contributing-guide
docs/api-documentation
```

### リファクタリング
```bash
refactor/対象
refactor/ble-manager
refactor/ui-components
refactor/settings-storage
```

### パフォーマンス改善
```bash
perf/対象
perf/reduce-latency
perf/optimize-rendering
```

### テスト
```bash
test/対象
test/add-ble-tests
test/integration-tests
```

## ワークフロー

### 1. イシューの作成（推奨）
```
GitHub Issues で作業内容を記録
例: #42 右クリック機能の追加
```

### 2. ブランチの作成
```bash
# mainブランチから最新を取得
git checkout main
git pull origin main

# 新しいブランチを作成
git checkout -b feature/right-click-support
```

### 3. 開発
```bash
# コード編集
# ...

# コミット（emoji prefix推奨）
git add .
git commit -m "✨ Add right click support with long press"

# 追加のコミット
git commit -m "🐛 Fix edge case in long press detection"
git commit -m "📝 Update README with right click documentation"
```

### 4. プッシュ
```bash
git push origin feature/right-click-support
```

### 5. Pull Request作成
GitHubで以下を含むPRを作成：

**タイトル:**
```
✨ Add right click support
```

**説明テンプレート:**
```markdown
## 変更内容
長押しで右クリックメニューを表示する機能を追加

## 関連Issue
Fixes #42

## テスト方法
1. Androidデバイスでアプリを起動
2. タッチパッドエリアを長押し
3. 右クリックメニューが表示されることを確認

## スクリーンショット
[スクリーンショット]

## チェックリスト
- [x] コードは既存のスタイルガイドに従っている
- [x] 自分でコードレビューを行った
- [x] テストを追加した
- [x] ドキュメントを更新した
- [x] CI/CDが成功している
```

### 6. コードレビュー
- CI/CDの自動チェックが完了するのを待つ
- レビュアーからのフィードバックに対応
- 必要に応じて追加コミット

### 7. マージ
**推奨マージ方法: Squash and merge**
- 複数のコミットを1つにまとめる
- コミット履歴がクリーンになる

```
✨ Add right click support (#42)

* Add long press detection
* Fix edge cases
* Update documentation
```

### 8. ブランチ削除
```bash
# リモートブランチ削除（GitHubで自動削除推奨）
git push origin --delete feature/right-click-support

# ローカルブランチ削除
git branch -d feature/right-click-support

# mainブランチに戻る
git checkout main
git pull origin main
```

## コミットメッセージのガイドライン

### Emoji Prefix（推奨）
- ✨ `:sparkles:` - 新機能
- 🐛 `:bug:` - バグ修正
- 📝 `:memo:` - ドキュメント
- ♻️ `:recycle:` - リファクタリング
- ⚡ `:zap:` - パフォーマンス改善
- 🎨 `:art:` - UIの改善
- 🔧 `:wrench:` - 設定変更
- ✅ `:white_check_mark:` - テスト追加
- 🚀 `:rocket:` - デプロイ関連
- 📦 `:package:` - 依存関係の更新

### 例
```bash
git commit -m "✨ Add scroll support for touchpad"
git commit -m "🐛 Fix cursor offset on double tap"
git commit -m "📝 Update README with new features"
git commit -m "♻️ Refactor BLE manager for better error handling"
git commit -m "⚡ Optimize cursor movement latency"
```

## ブランチ保護ルール

`main`ブランチは以下のルールで保護されています：

- ✅ Pull Request必須
- ✅ レビュー承認必須
- ✅ CI/CD成功必須
- ✅ 最新の状態でマージ必須
- ❌ 直接pushは禁止
- ❌ force pushは禁止

## CI/CDパイプライン

Pull Request作成時に自動実行：

1. **Code Analysis** (analyze job)
   - `flutter analyze`
   - `flutter test`

2. **Build macOS** (build-macos job)
   - macOSアプリのビルド
   - アーティファクトの生成

3. **Build Android** (build-android job)
   - Android APKのビルド
   - アーティファクトの生成

すべてのジョブが成功しないとマージできません。

## トラブルシューティング

### コンフリクトが発生した場合
```bash
# mainの最新を取得
git checkout main
git pull origin main

# 作業ブランチにマージ
git checkout feature/your-feature
git merge main

# コンフリクトを解決
# エディタで手動解決

# コミット
git add .
git commit -m "🔀 Merge main into feature branch"
git push origin feature/your-feature
```

### CI/CDが失敗した場合
1. エラーログを確認
2. ローカルで再現
3. 修正してpush
4. CI/CDが再実行される

### PRをクリーンにしたい場合
```bash
# インタラクティブrebase
git rebase -i main

# または、新しいブランチを作成
git checkout main
git pull origin main
git checkout -b feature/your-feature-v2
git cherry-pick <commit-hash>
```

## 参考リンク

- [GitHub Flow Guide](https://docs.github.com/en/get-started/quickstart/github-flow)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [Pull Request Template](PULL_REQUEST_TEMPLATE.md)
