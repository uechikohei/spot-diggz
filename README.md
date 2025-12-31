# 🛹 spot-diggz

**スケートスポット検索・シェアアプリケーションのモダンリプレイス版**

旧SkateSpotSearchをRust + TypeScript + GCPでフルリニューアル！

## 🚀 Quick Start (GitHub Codespaces)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=master&repo=uechikohei/spot-diggz)

1. 上記ボタンをクリックしてCodespacesを作成
2. 自動セットアップ完了まで待機（約3-5分）
3. 開発開始！

## 🛠️ Tech Stack

| Layer | Technology | 選定理由 |
|-------|------------|----------|
| **Backend** | Rust (スクラッチ実装) | パフォーマンス + 学習効果 |
| **Frontend** | React + TypeScript | 型安全性 + エコシステム |
| **Infrastructure** | GCP (Cloud Run, Firestore) | サーバーレス + コスト効率 |
| **IaC** | Terraform | Infrastructure as Code |
| **Development** | GitHub Codespaces + Docker | 統合開発環境 |

## 📁 Project Structure

```
spot-diggz/
├── .devcontainer/          # GitHub Codespaces設定
├── api/                   # 🦀 Rust APIサーバー
├── ui/                    # ⚛️ React UIアプリ
├── resources/             # 🏗️ Terraform Infrastructure
├── docs/                  # 📚 ドキュメント
└── scripts/               # 🔧 開発用スクリプト
```

## 🔧 Development Commands

```bash
# API開発
cd api && cargo run      # localhost:8080

# UI開発  
cd ui && npm run dev     # localhost:3000
```

<details>
<summary>動作確認手順（ローカル起動）</summary>

1) Rust API起動
```bash
cd api
export SDZ_USE_FIRESTORE=1
export SDZ_AUTH_PROJECT_ID=sdz-dev
export SDZ_FIRESTORE_PROJECT_ID=sdz-dev
export SDZ_FIRESTORE_TOKEN=$(gcloud auth print-access-token)
cargo run
```

2) React UI起動（別ターミナル）
```bash
cd ui
npm install
npm run dev
```

3) 画面確認
- UI: `http://localhost:3000`
- API: `http://localhost:8080/sdz/health`

</details>

<details>
<summary>動作確認手順（IDトークン取得→CRUDスモーク）</summary>

1) 環境変数を用意（秘匿情報は`.env.local`など非追跡ファイルに保存）
```bash
export SDZ_FIREBASE_WEB_API_KEY="YOUR_FIREBASE_WEB_API_KEY"
export SDZ_TEST_USER_EMAIL="YOUR_TEST_EMAIL"
export SDZ_TEST_USER_PASSWORD="YOUR_TEST_PASSWORD"
```

2) Firebase Auth REST APIでIDトークン取得
```bash
SDZ_ID_TOKEN=$(curl -sS "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${SDZ_FIREBASE_WEB_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${SDZ_TEST_USER_EMAIL}\",
    \"password\": \"${SDZ_TEST_USER_PASSWORD}\",
    \"returnSecureToken\": true
  }" | jq -r '.idToken')
```

3) CRUDスモークテスト実行
```bash
SDZ_API_URL=http://localhost:8080 SDZ_ID_TOKEN="${SDZ_ID_TOKEN}" ./scripts/firestore_crud_smoke.sh
```

4) 正常動作チェック
- `POST /sdz/spots` が200でspotIdを返す
- `GET /sdz/spots/{id}` が作成したスポットを返す
- `GET /sdz/spots` に作成スポットが含まれる

</details>

<details>
<summary>使うコマンド一覧</summary>

- `gh project item-list 2 --owner uechikohei --limit 50 --format json | jq -r '.items[] | \"#\\(.content.number) \\(.content.title) | Priority: \\(.priority)\"'` ProjectのPriority反映状況を一覧で確認する
- `gh project item-list 2 --owner uechikohei --limit 50 --format json | jq -r '.items[] | \"#\\(.content.number) \\(.content.title) | Priority: \\(.priority) | Status: \\(.status) | URL: \\(.content.url)\"'` Project課題の一覧を表示する
- `gh issue view ISSUE_NUMBER -R uechikohei/spot-diggz --json title,body,url` Issue本文を取得する
- `gh issue create -R uechikohei/spot-diggz -t \"TITLE\" -b \"BODY\"` Issueを作成する
- `gh project item-add 2 --owner uechikohei --url \"ISSUE_URL\"` IssueをProjectに追加する
- `gh project item-edit --project-id PVT_kwHOAx5dHc4BLgT- --id ITEM_ID --field-id PVTSSF_lAHOAx5dHc4BLgT-zg7DwBA --single-select-option-id OPTION_ID` ProjectのPriorityを更新する
- `SDZ_ID_TOKEN=... SDZ_API_URL=... ./scripts/firestore_crud_smoke.sh` Firestore実運用のCRUDをAPI経由でスモークテストする（`X-SDZ-Client: ios`付き）
- `SDZ_ID_TOKEN=$(curl -sS "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${SDZ_FIREBASE_WEB_API_KEY}" -H "Content-Type: application/json" -d "{\"email\":\"${SDZ_TEST_USER_EMAIL}\",\"password\":\"${SDZ_TEST_USER_PASSWORD}\",\"returnSecureToken\":true}" | jq -r '.idToken')` Firebase Auth REST APIでIDトークンを取得する

</details>

## ⚙️ 環境変数（API）

- `SDZ_AUTH_PROJECT_ID` … Firebase/Identity PlatformのプロジェクトID（例: sdz-dev）
- `SDZ_USE_FIRESTORE` … `1` でFirestore利用、未設定ならインメモリ
- `SDZ_FIRESTORE_PROJECT_ID` … FirestoreのプロジェクトID（省略時はSDZ_AUTH_PROJECT_IDを使用）
- `SDZ_FIRESTORE_TOKEN` … Firestore RESTに使うBearerトークン（`gcloud auth print-access-token` など）
- `SDZ_CORS_ALLOWED_ORIGINS` … カンマ区切りの許可オリジン（未設定時はlocalhost:3000のみ）
- `SDZ_STORAGE_BUCKET` … 画像アップロード先のCloud Storageバケット名
- `SDZ_STORAGE_SERVICE_ACCOUNT_EMAIL` … 署名URL生成に使うサービスアカウントのメール
- `SDZ_STORAGE_SIGNED_URL_EXPIRES_SECS` … 署名URLの有効期限（秒、デフォルト900）
- `SDZ_STORAGE_SIGNING_TOKEN` … 署名URL生成に使うアクセストークン（未設定時はSDZ_FIRESTORE_TOKENやメタデータ経由）

## 📚 Documentation

- [開発環境セットアップ](docs/DEVELOPMENT_SETUP.md)
- [運用ルール](AGENTS.md)

## 🔌 APIエンドポイント（現在の実装状況）
- `GET /sdz/health` … ヘルスチェック
- `GET /sdz/users/me` … 認証必須。Firebase IDトークンを検証し、Firestoreの`users/{uid}`またはメモリから返却
- `POST /sdz/spots` … 認証必須。UUIDの`spotId`を払い出し、Firestoreの`spots/{uuid}`またはメモリに保存
- `POST /sdz/spots/upload-url` … 認証必須。画像アップロード用の署名URLを発行（モバイル専用）
- `GET /sdz/spots/{id}` … 公開。Firestore/メモリから取得（存在しなければ404）
- `GET /sdz/spots` … 公開。Firestore/メモリから一覧を取得
