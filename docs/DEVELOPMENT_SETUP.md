# spot-diggz 開発環境セットアップガイド

## 🚀 GitHub Codespaces + ローカルVS Code 開発環境

spot-diggzプロジェクトは、GitHub Codespacesとローカル VS Codeを連携した統合開発環境を提供しています。

## 📋 前提条件

- GitHub アカウント
- VS Code（ローカル開発用）
- GitHub Codespaces拡張機能

## 🌐 GitHub Codespaces セットアップ

### 1. Codespacesの作成

```bash
# GitHubリポジトリページから
1. 「Code」ボタンをクリック
2. 「Codespaces」タブを選択
3. 「Create codespace on feature/replace」をクリック
```

### 2. 自動セットアップ

Codespacesが起動すると、`.devcontainer/setup.sh`が自動実行され、以下がセットアップされます：

- 🦀 Rust開発環境（cargo, rustc, clippy, rust-analyzer）
- 📦 Node.js/npm環境（React開発用）
- 🏗️ Terraform環境
- ☁️ Google Cloud CLI
- 🐳 Docker CLI
- ⚙️ VS Code拡張機能
- 📁 プロジェクト構造

### 3. 開発サービスの起動

```bash
# 開発用サービス（PostgreSQL, Redis）起動
./scripts/dev-start.sh

# 個別サービス起動
cd src/api && cargo run          # Rust API サーバー (ポート8080)
cd src/ui && npm start           # React 開発サーバー (ポート3000)
```

## 💻 ローカル VS Code 連携

### 1. GitHub Codespaces 拡張機能インストール

```bash
# VS Code 拡張機能
- GitHub Codespaces
- Remote - Containers
- Remote - SSH
```

### 2. Codespacesへの接続

1. VS Codeのコマンドパレット（`Ctrl+Shift+P`）を開く
2. `Codespaces: Connect to Codespace`を実行
3. 作成済みのCodespaceを選択

### 3. ワークスペースの開き方

```bash
# ワークスペースファイルを開く
File > Open Workspace from File > spot-diggz.code-workspace
```

## 🛠️ 開発ワークフロー

### プロジェクト構造

```
spot-diggz/
├── .devcontainer/          # Codespaces設定
│   ├── devcontainer.json   # VS Code + 拡張機能設定
│   ├── Dockerfile          # 開発環境イメージ
│   └── setup.sh           # 自動セットアップスクリプト
├── src/
│   ├── api/               # 🦀 Rust APIサーバー
│   └── ui/                # ⚛️ React UIアプリ
├── resources/             # 🏗️ Terraform インフラ
├── docs/                  # 📚 ドキュメント
├── scripts/               # 🔧 開発用スクリプト
└── spot-diggz.code-workspace  # VS Code ワークスペース設定
```

### VS Code タスク

`Ctrl+Shift+P` > `Tasks: Run Task` で以下のタスクを実行：

| タスク | 説明 | ショートカット |
|--------|------|-------------|
| 🦀 Build Rust API | Rust APIビルド | `Ctrl+Shift+B` |
| 🦀 Run Rust API | Rust API起動 | - |
| 🦀 Test Rust API | Rust APIテスト | `Ctrl+Shift+T` |
| ⚛️ Start React Dev Server | React開発サーバー起動 | - |
| ⚛️ Build React UI | React UIビルド | - |
| ⚛️ Test React UI | React UIテスト | - |
| 🏗️ Terraform Plan | インフラプラン表示 | - |
| 🚀 Start Development Environment | 開発環境一括起動 | - |

### デバッグ設定

- **Rust API デバッグ**: `F5`キーで `🦀 Debug Rust API` 設定実行
- **ブレークポイント**: コード行番号左をクリック
- **変数確認**: デバッグ時に Variables パネルで確認

## 🔧 環境固有設定

### Google Cloud 認証

```bash
# Codespaces内で実行
gcloud auth login
gcloud config set project sdz-dev  # 開発環境プロジェクト
```

### 環境変数設定

```bash
# .env ファイル作成（各サブプロジェクトで）
cd src/api
cat > .env << 'EOF'
RUST_LOG=debug
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/spot_diggz_dev
REDIS_URL=redis://localhost:6379
EOF

cd ../ui  
cat > .env << 'EOF'
REACT_APP_API_URL=http://localhost:8080
REACT_APP_ENVIRONMENT=development
EOF
```

## 📊 ポートフォワーディング

Codespacesで自動的に以下のポートがフォワードされます：

| ポート | サービス | アクセス |
|--------|----------|----------|
| 3000 | React UI | https://xxx-3000.githubpreview.dev |
| 8080 | Rust API | https://xxx-8080.githubpreview.dev |
| 5432 | PostgreSQL | 内部アクセスのみ |
| 6379 | Redis | 内部アクセスのみ |

## 🔍 トラブルシューティング

### よくある問題

#### 1. Rust コンパイルエラー

```bash
# Rust toolchain確認
rustc --version
cargo --version

# 依存関係更新
cd src/api
cargo update
```

#### 2. Node.js 依存関係エラー

```bash
# npm キャッシュクリア
cd src/ui
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

#### 3. ポート競合エラー

```bash
# 使用中ポート確認
lsof -i :3000
lsof -i :8080

# プロセス終了
kill -9 <PID>
```

#### 4. Docker サービス起動失敗

```bash
# Docker状態確認
docker ps -a

# サービス再起動
./scripts/dev-stop.sh
./scripts/dev-start.sh
```

### ログ確認

```bash
# Codespacesセットアップログ
cat /tmp/codespace-creation.log

# アプリケーションログ
cd src/api && cargo run          # Rust ログ
cd src/ui && npm start           # React ログ

# Dockerサービスログ
docker-compose -f docker-compose.dev.yml logs
```

## 📱 モバイル開発

GitHub Mobile アプリでもCodespacesにアクセス可能：

1. GitHub Mobile アプリインストール
2. リポジトリ > Codespaces から接続
3. ブラウザベース VS Code で編集

## 🔄 Codespaces ライフサイクル

### 一時停止・再開

```bash
# 自動一時停止：30分非アクティブ後
# 手動操作：GitHub > Codespaces > Stop codespace

# 再開時は状態が保持される（ファイル、環境変数、インストール済みツール）
```

### データ永続化

- **永続化される**：ホームディレクトリ（`/home/vscode`）
- **永続化される**：`/workspace`（プロジェクトファイル）
- **永続化されない**：Docker コンテナ内一時ファイル

### バックアップ推奨

```bash
# 重要な設定ファイルはGitで管理
git add .vscode/ .devcontainer/
git commit -m "update: 開発環境設定"
git push
```

## 🚀 高度な使用方法

### カスタム設定

```json
// .devcontainer/devcontainer.json カスタマイズ例
{
  "postCreateCommand": "bash .devcontainer/setup.sh && echo 'カスタム設定完了'",
  "containerEnv": {
    "CUSTOM_VAR": "custom_value"
  }
}
```

### 複数Codespaces運用

- **開発用**: feature/replace ブランチ
- **実験用**: feature/experiment ブランチ  
- **本番確認用**: master ブランチ

## 📚 参考リンク

- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [Dev Container specification](https://containers.dev/)

---

**🎉 Happy Coding with spot-diggz! 🛹**