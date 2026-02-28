#!/bin/bash

# spot-diggz開発環境セットアップスクリプト
set -e

echo "🚀 spot-diggz開発環境をセットアップ中..."

# 環境変数読み込み
source ~/.bashrc 2>/dev/null || true
source ~/.zshrc 2>/dev/null || true
source ~/.nvm/nvm.sh 2>/dev/null || true
source ~/.cargo/env 2>/dev/null || true

# ディレクトリ構造作成
echo "📁 プロジェクト構造を作成中..."
mkdir -p \
    web/api \
    web/ui \
    web/resources/modules \
    web/resources/environments/{dev,stg,prod} \
    web/scripts \
    docs \
    .github/workflows \
    IOS \
    Android

# Git設定確認・初期化
echo "🔧 Git設定を確認中..."
if [ ! -f ~/.gitconfig ]; then
    echo "Git設定が見つからないため、デフォルト設定を適用します"
    git config --global user.name "spot-diggz-dev"
    git config --global user.email "dev@spot-diggz.local"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
fi

# Rust環境確認
echo "🦀 Rust環境を確認中..."
if command -v rustc &> /dev/null; then
    echo "✅ Rust version: $(rustc --version)"
    echo "✅ Cargo version: $(cargo --version)"
    
    # Rust APIディレクトリ初期化
    if [ ! -f web/api/Cargo.toml ]; then
        echo "📦 Rust APIプロジェクトを初期化中..."
        cd web/api
    cargo init --name sdz_api --bin .
        
        # 基本的な依存関係を追加
        cat >> Cargo.toml << 'EOF'

[dependencies]
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
reqwest = { version = "0.11", features = ["json"] }
uuid = { version = "1.6", features = ["v4"] }
chrono = { version = "0.4", features = ["serde"] }
anyhow = "1.0"
thiserror = "1.0"
tracing = "0.1"
tracing-subscriber = "0.3"

[dev-dependencies]
pretty_assertions = "1.4"
EOF
        cd /workspace
    fi
else
    echo "❌ Rust未インストール"
fi

# Node.js環境確認
echo "📦 Node.js環境を確認中..."
if command -v node &> /dev/null; then
    echo "✅ Node.js version: $(node --version)"
    echo "✅ npm version: $(npm --version)"
    
    # React UIディレクトリ初期化
    if [ ! -f web/ui/package.json ]; then
        echo "⚛️ React UIプロジェクトを初期化中..."
        cd web/ui
        npx create-react-app . --template typescript
        
        # 追加依存関係インストール
        npm install --save \
            @types/react @types/react-dom \
            tailwindcss @tailwindcss/forms @tailwindcss/typography \
            axios react-router-dom @types/react-router-dom \
            @headlessui/react @heroicons/react
            
        # 開発依存関係
        npm install --save-dev \
            eslint-config-prettier prettier \
            @typescript-eslint/eslint-plugin @typescript-eslint/parser
            
        cd /workspace
    fi
else
    echo "❌ Node.js未インストール"
fi

# Terraform環境確認
echo "🏗️ Terraform環境を確認中..."
if command -v terraform &> /dev/null; then
    echo "✅ Terraform version: $(terraform --version | head -n1)"
    
    # Terraformモジュール初期化
    if [ ! -f web/resources/main.tf ]; then
        echo "🌍 Terraformプロジェクトを初期化中..."
        
        # メインTerraformファイル作成
        cat > web/resources/main.tf << 'EOF'
# spot-diggz Infrastructure
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  # TODO: 本番環境ではremote backendを設定
  # backend "gcs" {
  #   bucket = "sdz-terraform-state"
  #   prefix = "terraform/state"
  # }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "Environment (dev/stg/prod)"
  type        = string
  default     = "dev"
}

# Provider設定
provider "google" {
  project = var.project_id
  region  = var.region
}
EOF

        # 環境別設定ファイル作成
        for env in dev stg prod; do
            cat > web/resources/environments/$env/terraform.tfvars << EOF
project_id  = "sdz-$env"
region      = "asia-northeast1"
environment = "$env"
EOF
        done
    fi
else
    echo "❌ Terraform未インストール"
fi

# Google Cloud CLI確認
echo "☁️ Google Cloud CLI環境を確認中..."
if command -v gcloud &> /dev/null; then
    echo "✅ Google Cloud CLI version: $(gcloud --version | head -n1)"
    echo "ℹ️  ログインは手動で実行してください: gcloud auth login"
else
    echo "❌ Google Cloud CLI未インストール"
fi

# Docker環境確認
echo "🐳 Docker環境を確認中..."
if command -v docker &> /dev/null; then
    echo "✅ Docker CLI version: $(docker --version)"
    
    # 開発用docker-compose.yml作成
    if [ ! -f docker-compose.dev.yml ]; then
        echo "🐳 開発用Docker Compose設定を作成中..."
        cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  # 開発用PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: spot_diggz_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  # 開発用Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOF
    fi
else
    echo "❌ Docker CLI未インストール"
fi

# VS Code設定ディレクトリ作成
echo "⚙️ VS Code設定を作成中..."
mkdir -p .vscode

# プロジェクト用settings.json
cat > .vscode/settings.json << 'EOF'
{
  "rust-analyzer.cargo.loadOutDirsFromCheck": true,
  "rust-analyzer.procMacro.enable": true,
  "rust-analyzer.checkOnSave.command": "clippy",
  "typescript.preferences.quoteStyle": "double",
  "javascript.preferences.quoteStyle": "double",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.eslint.fixAll": true
  },
  "files.watcherExclude": {
    "**/target/**": true,
    "**/node_modules/**": true,
    "**/.terraform/**": true
  },
  "search.exclude": {
    "**/target": true,
    "**/node_modules": true,
    "**/.terraform": true
  },
  "terminal.integrated.defaultProfile.linux": "bash"
}
EOF

# VS Code tasks.json
cat > .vscode/tasks.json << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Rust: Build API",
      "type": "shell",
      "command": "cargo",
      "args": ["build"],
      "options": {
        "cwd": "${workspaceFolder}/web/api"
      },
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "React: Start Dev Server",
      "type": "shell", 
      "command": "npm",
      "args": ["start"],
      "options": {
        "cwd": "${workspaceFolder}/web/ui"
      },
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Terraform: Plan",
      "type": "shell",
      "command": "terraform",
      "args": ["plan"],
      "options": {
        "cwd": "${workspaceFolder}/web/resources"
      },
      "group": "build"
    }
  ]
}
EOF

# launch.json（デバッグ設定）
cat > .vscode/launch.json << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Rust API",
      "type": "lldb",
      "request": "launch",
      "program": "${workspaceFolder}/web/api/target/debug/sdz_api",
      "args": [],
      "cwd": "${workspaceFolder}/web/api",
      "sourceLanguages": ["rust"]
    }
  ]
}
EOF

# 開発用スクリプト作成
echo "📝 開発用スクリプトを作成中..."
mkdir -p web/scripts

cat > web/scripts/dev-start.sh << 'EOF'
#!/bin/bash
# 開発環境一括起動スクリプト

echo "🚀 spot-diggz開発環境を起動中..."

# Docker Composeでサービス起動
docker-compose -f docker-compose.dev.yml up -d

echo "✅ 開発サービスが起動しました"
echo "📦 PostgreSQL: localhost:5432"
echo "🔴 Redis: localhost:6379"
echo ""
echo "次のコマンドで開発を開始:"
echo "  cd web/api && cargo run    # Rust API"
echo "  cd web/ui && npm start     # React UI"
EOF

cat > web/scripts/dev-stop.sh << 'EOF'
#!/bin/bash
# 開発環境停止スクリプト

echo "🛑 spot-diggz開発環境を停止中..."
docker-compose -f docker-compose.dev.yml down
echo "✅ 開発環境を停止しました"
EOF

chmod +x web/scripts/*.sh

# .gitignore更新
echo "📝 .gitignoreを更新中..."
cat > .gitignore << 'EOF'
# Rust
target/
Cargo.lock

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.pnpm-debug.log*

# TypeScript
*.tsbuildinfo

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Terraform
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl

# IDE
.vscode/settings.json
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Cache
.cache/
.tmp/

# Build outputs
dist/
build/
EOF

echo ""
echo "🎉 spot-diggz開発環境のセットアップが完了しました！"
echo ""
echo "📋 次のステップ:"
echo "1. GitHub Codespacesまたはローカル VS Codeで開発を開始"
echo "2. Google Cloud CLI認証: gcloud auth login"
echo "3. 開発サービス起動: ./web/scripts/dev-start.sh"
echo "4. API開発: cd web/api && cargo run"
echo "5. UI開発: cd web/ui && npm start"
echo ""
echo "📚 詳細なドキュメントはCLAUDE.mdを参照してください"
