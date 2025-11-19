# ブランチ保護設定ガイド

このドキュメントは、`main`ブランチを保護するためのGitHub設定手順を説明します。

## 設定手順

### 1. GitHubリポジトリの設定ページに移動

```
https://github.com/Kazuki-0731/remote-touch/settings
```

または、リポジトリページから：
```
Settings → Branches
```

### 2. Branch protection rule を追加

**"Add branch protection rule"** をクリック

### 3. ブランチ名を指定

**Branch name pattern:**
```
main
```

### 4. 保護ルールを設定

以下の項目をチェック：

#### ✅ Require a pull request before merging
- **Require approvals**: 1 (少なくとも1人の承認が必要)
  - 個人プロジェクトの場合は0でもOK
  - チーム開発の場合は1以上を推奨
- **Dismiss stale pull request approvals when new commits are pushed**: チェック推奨
  - 新しいコミットがpushされたら承認をリセット
- **Require review from Code Owners**: チェック不要（CODEOWNERS未設定の場合）

#### ✅ Require status checks to pass before merging
- **Require branches to be up to date before merging**: チェック
- **Status checks that are required:** 以下を追加
  - `analyze` (コード解析)
  - `build-macos` (macOSビルド)
  - `build-android` (Androidビルド)

> **注意**: 初回のCI/CDが実行されるまで、これらのステータスチェックは表示されません。最初のPRを作成した後に追加してください。

#### ✅ Require conversation resolution before merging
- レビューコメントの議論を解決してからマージ

#### ✅ Require signed commits (オプション)
- GPG署名されたコミットのみを許可（セキュリティ重視の場合）

#### ✅ Require linear history (推奨)
- マージコミットを禁止し、リニアな履歴を維持
- "Squash and merge" または "Rebase and merge" を強制

#### ✅ Include administrators
- 管理者（あなた）にもルールを適用
- 推奨: チェックを入れて、自分も例外にしない

#### ❌ Allow force pushes
- チェックしない（force pushを禁止）

#### ❌ Allow deletions
- チェックしない（mainブランチの削除を禁止）

### 5. 保存

**"Create"** または **"Save changes"** をクリック

## 設定後の動作

### ✅ できること
- Pull Requestの作成
- Pull Requestのレビュー
- CI/CDが成功したPRのマージ

### ❌ できないこと
- mainブランチへの直接push
- CI/CD失敗したPRのマージ
- レビュー未承認のPRのマージ（承認必須に設定した場合）
- mainブランチのforce push
- mainブランチの削除

## 設定確認

### テスト方法

1. **直接pushを試す**（失敗するはず）
```bash
git checkout main
git commit --allow-empty -m "Test commit"
git push origin main
```

期待される結果：
```
remote: error: GH006: Protected branch update failed
```

2. **Pull Requestを作成**（成功するはず）
```bash
git checkout -b test/branch-protection
git commit --allow-empty -m "✅ Test branch protection"
git push origin test/branch-protection
```

GitHubでPRを作成 → CI/CDが実行 → マージボタンが有効になる

## 推奨設定サマリー

| 設定項目 | 個人開発 | チーム開発 |
|---------|---------|-----------|
| **Require pull request** | ✅ | ✅ |
| **Require approvals** | 0 | 1+ |
| **Require status checks** | ✅ | ✅ |
| **Require conversation resolution** | ✅ | ✅ |
| **Require signed commits** | ❌ | ✅ (推奨) |
| **Require linear history** | ✅ | ✅ |
| **Include administrators** | ✅ | ✅ |
| **Allow force pushes** | ❌ | ❌ |
| **Allow deletions** | ❌ | ❌ |

## トラブルシューティング

### Q: マージボタンが押せない
**A:** 以下を確認：
- [ ] すべてのCI/CDが成功しているか
- [ ] ブランチが最新の状態か
- [ ] 必要な承認が得られているか（承認必須の場合）
- [ ] すべてのコメントが解決されているか

### Q: 自分のPRなのに承認が必要
**A:** "Require approvals" を0に設定するか、別のアカウントでレビュー

### Q: CI/CDのステータスチェックが表示されない
**A:** 最初のPRを作成してCI/CDを実行してから、設定に戻って追加

### Q: 緊急で直接mainにpushしたい
**A:**
1. 一時的にブランチ保護を無効化
2. Push
3. すぐにブランチ保護を再有効化
4. 緊急対応後、適切なPRを作成して履歴を整理

## マージ戦略の設定

リポジトリ設定で、マージ方法を制限できます：

```
Settings → General → Pull Requests
```

**推奨設定:**
- ✅ **Allow squash merging** (推奨)
  - 複数コミットを1つにまとめる
  - クリーンな履歴
- ❌ Allow merge commits
  - マージコミットが増える
- ❌ Allow rebase merging
  - 履歴が変わる可能性

**デフォルトマージ方法:**
- **Squash and merge** を選択

## 自動ブランチ削除

```
Settings → General → Pull Requests
→ ✅ Automatically delete head branches
```

マージ後、自動的にブランチを削除します。

## 参考

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [BRANCH_STRATEGY.md](BRANCH_STRATEGY.md)
