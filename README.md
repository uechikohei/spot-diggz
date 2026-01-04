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

## 🧭 開発のすすめかた

- 開発環境セットアップ: `docs/DEVELOPMENT_SETUP.md`
- CD設計: `docs/cd_architecture.md`
- PR作成時は `.github/workflows/ci.yml` に定義されたユニットテストが自動実行される
- ローカルでの起動手順は下記の「動作確認手順（ローカル起動）」を参照
- Terraformのバージョンは `.terraform-version` で固定（tfenv想定）

<details>
<summary>動作確認手順（ローカル起動）</summary>

1) Rust API起動
```bash
cd api
# api/.env に必要な値を設定済みであること
set -a
source ./.env
set +a
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
payload=$(jq -n --arg email "${SDZ_TEST_USER_EMAIL}" \
  --arg password "${SDZ_TEST_USER_PASSWORD}" \
  '{email:$email,password:$password,returnSecureToken:true}')

SDZ_ID_TOKEN=$(curl -sS "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${SDZ_FIREBASE_WEB_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${payload}" | jq -r '.idToken')
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
- `gh pr create -R uechikohei/spot-diggz -t \"TITLE\" -b \"BODY\"` Pull Requestを作成する
- `gh pr reopen ISSUE_NUMBER -R uechikohei/spot-diggz` Close済みのPull Requestを再オープンする
- `gh pr edit ISSUE_NUMBER -R uechikohei/spot-diggz --base develop` Pull Requestのベースブランチを変更する
- `gh project item-add 2 --owner uechikohei --url \"ISSUE_URL\"` IssueをProjectに追加する
- `gh project item-edit --project-id PVT_kwHOAx5dHc4BLgT- --id ITEM_ID --field-id PVTSSF_lAHOAx5dHc4BLgT-zg7DwBA --single-select-option-id OPTION_ID` ProjectのPriorityを更新する
- `SDZ_ID_TOKEN=... SDZ_API_URL=... ./scripts/firestore_crud_smoke.sh` Firestore実運用のCRUDをAPI経由でスモークテストする（`X-SDZ-Client: ios`付き）
- `payload=$(jq -n --arg email "${SDZ_TEST_USER_EMAIL}" --arg password "${SDZ_TEST_USER_PASSWORD}" '{email:$email,password:$password,returnSecureToken:true}'); SDZ_ID_TOKEN=$(curl -sS "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${SDZ_FIREBASE_WEB_API_KEY}" -H "Content-Type: application/json" -d "${payload}" | jq -r '.idToken')` Firebase Auth REST APIでIDトークンを取得する
- `ls` リポジトリ直下のファイル一覧を確認する
- `cat docs/cd_architecture.md` CD設計ドキュメントの内容を確認する
- `rg -n "開発のすすめかた|開発の進め方|開発" README.md` README内の開発導線の位置を検索する
- `cat README.md` README全体の記載内容を確認する
- `git status -sb` 変更状況と現在ブランチを短く確認する
- `git commit -m "MESSAGE"` 変更内容をコミットする
- `git commit --amend` 直前のコミット内容を修正する
- `git push --force-with-lease` リモートの最新を確認した上で履歴を書き換えてpushする
- `git push -u origin feature/wif-terraform` 作業ブランチをリモートへ初回pushする
- `rg --files .github/workflows` GitHub Actionsのワークフローファイルを列挙する
- `cat .github/workflows/ci.yml` CI設定の詳細を確認する
- `cargo fmt -- --check` Rustのフォーマットをチェックする
- `cargo clippy -- -D warnings` RustのLintを警告扱いで実行する
- `cargo test --verbose` Rustのユニットテストを詳細ログ付きで実行する
- `cargo build --release --verbose` Rustのリリースビルドを詳細ログ付きで実行する
- `test -f ui/package-lock.json && echo "package-lock.json exists"` UIのlockfile有無を確認する
- `npm ci` UIの依存関係をlockfile通りにインストールする
- `npm run lint` UIのLintを実行する
- `npm run type-check` UIの型チェックを実行する
- `npm test -- --coverage --watch=false` UIのユニットテストをカバレッジ付きで実行する
- `npm run build` UIの本番ビルドを実行する
- `brew install tfsec trivy colima docker docker-credential-helper` ローカルでtfsec/trivy/Docker環境を用意する
- `colima start` ローカルのDockerデーモン（Colima）を起動する
- `docker build -f .devcontainer/Dockerfile .` devcontainer用Dockerイメージのビルドを検証する
- `terraform fmt -check -recursive` Terraformのフォーマット差分をチェックする
- `terraform fmt -recursive` Terraformのフォーマットを整形する
- `terraform init` Terraformの初期化を行う
- `terraform plan -var-file=environments/dev/terraform.tfvars` dev環境の実行計画を確認する
- `terraform init -backend=false` Terraformをローカル検証用に初期化する
- `terraform validate` Terraformの設定を検証する
- `tfsec resources` Terraform設定のセキュリティスキャンを実行する
- `gh run list --branch feature/p2-iac-cicd --limit 5` 特定ブランチのGitHub Actions実行履歴を確認する
- `gh run view RUN_ID --log-failed` 指定ランの失敗ログのみを確認する
- `rg -n "workload identity|workload_identity|workloadIdentity|iam_workload|oidc|federation" -S resources` WIF関連の設定がTerraformに存在するか検索する
- `ls resources` Terraform配下の構成を一覧で確認する
- `cat resources/environments/dev/main.tf` dev環境のTerraform定義を確認する
- `cat resources/variables.tf` Terraformのルート変数を確認する
- `cat resources/main.tf` Terraformのルートモジュール配線を確認する
- `cat resources/environments/dev/terraform.tfvars.example` dev環境のtfvars例を確認する
- `git switch develop` developブランチへ切り替える
- `git switch -c feature/wif-terraform` 作業用ブランチを新規作成して切り替える
- `git switch -c feature/cloudbuild-permissions` Cloud Build権限調整の作業用ブランチを作成する
- `rg -n "cloudbuild|cloud build|gcloud builds|Cloud Build" -S .` Cloud Build関連の定義や記載を検索する
- `ls resources/cloudbuild/*.yaml` Cloud Buildの設定ファイル一覧を確認する
- `gcloud builds submit --project "sdz-dev" --config resources/cloudbuild/cloudbuild_api.yaml --substitutions _PROJECT_ID="sdz-dev",_REGION="asia-northeast1",_STAGE="dev",_API_IMAGE="asia-northeast1-docker.pkg.dev/sdz-dev/sdz-dev-api/sdz-api:latest",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com"` Cloud BuildでAPIのビルド・デプロイを実行する
- `gcloud builds submit --project "sdz-dev" --config resources/cloudbuild/cloudbuild_ui.yaml --substitutions _UI_BUCKET="sdz-dev-ui-bucket",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com",_VITE_SDZ_API_URL="https://sdz-dev-api-xxxxx.a.run.app",_VITE_FIREBASE_API_KEY="***",_VITE_FIREBASE_AUTH_DOMAIN="***",_VITE_FIREBASE_PROJECT_ID="sdz-dev"` Cloud BuildでUIのビルド・配信を実行する
- `set -a; source ui/.env.local; set +a; gcloud builds submit --project "sdz-dev" --config resources/cloudbuild/cloudbuild_ui.yaml --substitutions _UI_BUCKET="sdz-dev-ui-bucket",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com",_VITE_SDZ_API_URL="${VITE_SDZ_API_URL}",_VITE_FIREBASE_API_KEY="${VITE_FIREBASE_API_KEY}",_VITE_FIREBASE_AUTH_DOMAIN="${VITE_FIREBASE_AUTH_DOMAIN}",_VITE_FIREBASE_PROJECT_ID="${VITE_FIREBASE_PROJECT_ID}"` ui/.env.local の VITE_* を読み込んでCloud BuildでUIのビルド・配信を実行する
- `trivy fs .` リポジトリ全体の脆弱性/シークレットスキャンを実行する

</details>

## ⚙️ 環境変数（API）

- `api/.env.example` をコピーして `api/.env` を作成する（秘匿情報はコミットしない）
- `SDZ_AUTH_PROJECT_ID` … Firebase/Identity PlatformのプロジェクトID（例: sdz-dev）
- `SDZ_USE_FIRESTORE` … `1` でFirestore利用、未設定ならインメモリ
- `SDZ_FIRESTORE_PROJECT_ID` … FirestoreのプロジェクトID（省略時はSDZ_AUTH_PROJECT_IDを使用）
- `SDZ_FIRESTORE_TOKEN` … Firestore RESTに使うBearerトークン（`gcloud auth print-access-token` など）
- `SDZ_CORS_ALLOWED_ORIGINS` … カンマ区切りの許可オリジン（未設定時はlocalhost:3000のみ）
- `SDZ_STORAGE_BUCKET` … 画像アップロード先のCloud Storageバケット名
- `SDZ_STORAGE_SERVICE_ACCOUNT_EMAIL` … 署名URL生成に使うサービスアカウントのメール
- `SDZ_STORAGE_SIGNED_URL_EXPIRES_SECS` … 署名URLの有効期限（秒、デフォルト900）
- `SDZ_STORAGE_SIGNING_TOKEN` … 署名URL生成に使うアクセストークン（未設定時はSDZ_FIRESTORE_TOKENやメタデータ経由）
  
UIの環境変数（`VITE_*`）は `ui/.env.local` に設定する。例は `docs/DEVELOPMENT_SETUP.md` を参照。

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
