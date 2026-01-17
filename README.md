# 🛹 spot-diggz

**スケートスポット検索・シェアアプリケーションのリプレイスプロジェクト**

旧SkateSpotSearchをRust + TypeScript + GCPで再構築

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
├── .github/               # GitHub Actionsなど
├── web/                   # Webアプリ（API/UI/IaC）
│   ├── api/               # 🦀 Rust APIサーバー
│   ├── ui/                # ⚛️ React UIアプリ
│   ├── resources/         # 🏗️ Terraform Infrastructure
│   ├── scripts/           # 🔧 開発用スクリプト
│   └── sample/            # 🧪 Seed用画像サンプル
├── docs/                  # 📚 ドキュメント
├── iOS/                   # iOSアプリ（予定）
├── android/               # Androidアプリ（予定）
├── AGENTS.md              # Codex運用ルール
├── .gitignore             # 追跡対象外ファイル
├── README.md              # リポジトリ概要
└── spot-diggz.code-workspace  # VS Code ワークスペース設定
```

## 🔧 Development Commands

```bash
# API開発
cd web/api && cargo run  # localhost:8080

# UI開発  
cd web/ui && npm run dev # localhost:3000
```

## 🧭 開発のすすめかた

- 開発環境セットアップ: `docs/DEVELOPMENT_SETUP.md`
- CD設計: `docs/cd_architecture.md`
- dev seed運用ルール: `docs/seed_runbook.md`
- PR作成時は `.github/workflows/ci.yml` に定義されたユニットテストが自動実行される
- ローカルでの起動手順は下記の「動作確認手順（ローカル起動）」を参照
- Terraformのバージョンは `web/.terraform-version` で固定（tfenv想定）

<details>
<summary>動作確認手順（ローカル起動）</summary>

1) Rust API起動
```bash
cd web/api
# web/api/.env に必要な値を設定済みであること
set -a
source ./.env
set +a
export SDZ_FIRESTORE_TOKEN=$(gcloud auth print-access-token)
cargo run
```

2) React UI起動（別ターミナル）
```bash
cd web/ui
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
SDZ_API_URL=http://localhost:8080 SDZ_ID_TOKEN="${SDZ_ID_TOKEN}" ./web/scripts/firestore_crud_smoke.sh
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
- `gh issue edit ISSUE_NUMBER -R uechikohei/spot-diggz --title \"TITLE\" --body-file PATH` Issueのタイトル/本文を更新する
- `gh pr create -R uechikohei/spot-diggz -t \"TITLE\" -b \"BODY\"` Pull Requestを作成する
- `gh pr create -R uechikohei/spot-diggz --base develop --head feature/tiddy-repo -t \"TITLE\" -F /tmp/pr-body.md` ベース/ヘッドを指定し、本文をファイルで指定してPull Requestを作成する
- `gh pr create -R uechikohei/spot-diggz --base develop --head hotfix/NAME -t \"TITLE\" -b \"BODY\"` hotfixブランチからdevelop向けのPull Requestを作成する
- `gh pr view PR_NUMBER -R uechikohei/spot-diggz --json title,author,baseRefName,headRefName,state,mergeable,mergeStateStatus,labels,files` Pull Requestの概要と変更ファイルをJSONで確認する
- `gh pr reopen ISSUE_NUMBER -R uechikohei/spot-diggz` Close済みのPull Requestを再オープンする
- `gh pr edit ISSUE_NUMBER -R uechikohei/spot-diggz --base develop` Pull Requestのベースブランチを変更する
- `gh pr merge PR_NUMBER -R uechikohei/spot-diggz --merge` Pull Requestをマージ（merge commit）する
- `gh project item-add 2 --owner uechikohei --url \"ISSUE_URL\"` IssueをProjectに追加する
- `gh project item-edit --project-id PVT_kwHOAx5dHc4BLgT- --id ITEM_ID --field-id PVTSSF_lAHOAx5dHc4BLgT-zg7DwBA --single-select-option-id OPTION_ID` ProjectのPriorityを更新する
- `SDZ_ID_TOKEN=... SDZ_API_URL=... ./web/scripts/firestore_crud_smoke.sh` Firestore実運用のCRUDをAPI経由でスモークテストする（`X-SDZ-Client: ios`付き）
- `payload=$(jq -n --arg email "${SDZ_TEST_USER_EMAIL}" --arg password "${SDZ_TEST_USER_PASSWORD}" '{email:$email,password:$password,returnSecureToken:true}'); SDZ_ID_TOKEN=$(curl -sS "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${SDZ_FIREBASE_WEB_API_KEY}" -H "Content-Type: application/json" -d "${payload}" | jq -r '.idToken')` Firebase Auth REST APIでIDトークンを取得する
- `ls` リポジトリ直下のファイル一覧を確認する
- `ls -a` 隠しファイルを含めて一覧を確認する
- `cat docs/cd_architecture.md` CD設計ドキュメントの内容を確認する
- `rg -n "開発のすすめかた|開発の進め方|開発" README.md` README内の開発導線の位置を検索する
- `rg -n "api/|ui/|resources/|scripts/|sdz_seed_spots|\\.terraform-version" README.md` README内の旧パス参照を確認する
- `rg -n "cd api|cd ui|api/\\.env|ui/\\.env" docs/DEVELOPMENT_SETUP.md` DEVELOPMENT_SETUPの旧パス参照を確認する
- `rg -n "API URL|run.app|SDZ_API_URL|VITE_SDZ_API_URL" docs/DEVELOPMENT_SETUP.md` API URL関連の記載箇所を検索する
- `rg -n "sdz-dev|run.app|api" docs/cd_architecture.md` CD設計内のAPI関連記載を検索する
- `rg -n "SDZ_API_URL|VITE_SDZ_API_URL|run.app|sdz-dev-api|Cloud Run|cloud run|Base URL|base url" docs README.md web -g"*.md" -g"*.yaml" -g"*.yml" -g"*.env*"` API URLやCloud Runの記載をドキュメントと設定ファイル横断で確認する
- `rg -n "SDZ|sdz|api" web/ui/src` UI側のAPI/SDZ関連の実装箇所を検索する
- `rg -n "Authorization|Bearer" web/ui/src` UI側の認証ヘッダー利用有無を確認する
- `rg -n "User" web/ui/src/types` UIの型定義でUser関連があるか確認する
- `rg -n "sdz" web/api/src` API側のsdz関連実装を横断検索する
- `rg -n "Cloud Run|cloud run|run.app|ingress|allUsers|iam|invoker" -S web docs .github` Cloud Run公開設定の痕跡をドキュメントと設定で確認する
- `rg -n "cloud_run|run.invoker|allUsers|invoker|ingress" -S web/resources` TerraformのCloud Run公開/IAM設定を確認する
- `rg -n "SdzApiClient|SdzEnvironment|SdzAppState|fetchSpots|fetchSpot" iOS/spot-diggz` iOSのAPI連携関連コードをまとめて検索する
- `rg -n "xcodeproj|xcworkspace|xcuserdata" .gitignore` .gitignoreのXcode関連除外設定を確認する
- `rg --files iOS/Data iOS/Domain iOS/Presentation` iOS配下の実装ファイル一覧を確認する
- `cat README.md` README全体の記載内容を確認する
- `cat -n FILE` 行番号付きでファイル内容を確認する
- `sed -n '1,200p' FILE` ファイルの先頭200行を確認する
- `git status -sb` 変更状況と現在ブランチを短く確認する
- `git fetch origin` リモートの最新情報を取得する
- `git merge origin/develop` developの変更を取り込み、競合を解消する
- `git switch develop` developブランチへ切り替える
- `git switch master` masterブランチへ切り替える
- `git pull --ff-only` リモート更新をfast-forwardで取り込む
- `git merge develop` developの変更をmasterへ取り込む
- `git tag -a v0.1.0-web-mvp -m "web mvp dev release"` web版MVPのリリースタグを作成する
- `git switch -c hotfix/NAME` hotfixブランチを作成して切り替える
- `git add README.md` READMEの変更のみをステージする
- `git add PATH` 指定ファイルをステージする
- `git rm -r PATH` 指定ディレクトリ配下のファイルを削除してステージする
- `git diff FILE` 指定ファイルの差分を確認する
- `git commit -m "MESSAGE"` 変更内容をコミットする
- `git commit --amend` 直前のコミット内容を修正する
- `git stash push -m "MESSAGE"` 作業中の変更をスタッシュへ退避する
- `git stash push -u -m "MESSAGE"` 未追跡ファイルも含めてスタッシュへ退避する
- `git stash pop` 退避した変更を作業ツリーへ戻す
- `git branch -m NEW_NAME` 現在のブランチ名を変更する
- `git push --force-with-lease` リモートの最新を確認した上で履歴を書き換えてpushする
- `git push origin master` masterブランチをリモートへpushする
- `git push origin develop` developブランチをリモートへpushする
- `git push -u origin feature/wif-terraform` 作業ブランチをリモートへ初回pushする
- `git push -u origin feature/tiddy-repo` 作業ブランチをリモートへ初回pushする
- `git push -u origin hotfix/NAME` hotfixブランチをリモートへ初回pushする
- `git push origin v0.1.0-web-mvp` 指定タグをリモートへpushする
- `touch iOS/.gitkeep android/.gitkeep` 空ディレクトリをGitで追跡するためのファイルを作成する
- `rg -n "ios/" -S .` iOSディレクトリ参照の有無を検索する
- `rg -n "iOS|Android" -S .` iOS/Androidの表記揺れや参照箇所を検索する
- `git mv ios ios_tmp && git mv ios_tmp iOS` iOSディレクトリへリネームする（大小文字のみ変更する場合の安全策）
- `git mv Android android_tmp && git mv android_tmp android` androidディレクトリにリネームする（大小文字のみ変更する場合の安全策）
- `curl -sS -o /dev/null -w "%{http_code}\n" "URL"` APIのHTTPステータスだけを確認する
- `curl -sS "URL" | head -c 200` APIレスポンスの先頭を確認する
- `rg --files .github/workflows` GitHub Actionsのワークフローファイルを列挙する
- `cat .github/workflows/ci.yml` CI設定の詳細を確認する
- `cargo fmt` Rustのフォーマットを整形する
- `cargo fmt -- --check` Rustのフォーマットをチェックする
- `cargo clippy -- -D warnings` RustのLintを警告扱いで実行する
- `cargo test --verbose` Rustのユニットテストを詳細ログ付きで実行する
- `cargo build --release --verbose` Rustのリリースビルドを詳細ログ付きで実行する
- `test -f web/ui/package-lock.json && echo "package-lock.json exists"` UIのlockfile有無を確認する
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
- `terraform plan -var-file=web/resources/environments/dev/terraform.tfvars` dev環境の実行計画を確認する
- `terraform init -backend=false` Terraformをローカル検証用に初期化する
- `terraform validate` Terraformの設定を検証する
- `tfsec web/resources` Terraform設定のセキュリティスキャンを実行する
- `gh run list --branch feature/p2-iac-cicd --limit 5` 特定ブランチのGitHub Actions実行履歴を確認する
- `gh run view RUN_ID --log-failed` 指定ランの失敗ログのみを確認する
- `gh issue list --limit 10` Issue一覧を直近10件で表示する
- `gh label list --limit 200` 既存ラベル一覧を確認する
- `rg -n "workload identity|workload_identity|workloadIdentity|iam_workload|oidc|federation" -S web/resources` WIF関連の設定がTerraformに存在するか検索する
- `ls web/resources` Terraform配下の構成を一覧で確認する
- `cat web/resources/environments/dev/main.tf` dev環境のTerraform定義を確認する
- `cat web/resources/variables.tf` Terraformのルート変数を確認する
- `cat web/resources/main.tf` Terraformのルートモジュール配線を確認する
- `cat web/resources/environments/dev/terraform.tfvars.example` dev環境のtfvars例を確認する
- `git switch develop` developブランチへ切り替える
- `git switch -c feature/wif-terraform` 作業用ブランチを新規作成して切り替える
- `git switch -c feature/cloudbuild-permissions` Cloud Build権限調整の作業用ブランチを作成する
- `git switch -c feature/ios-prep` iOS関連の作業用ブランチを新規作成して切り替える
- `rg -n "cloudbuild|cloud build|gcloud builds|Cloud Build" -S .` Cloud Build関連の定義や記載を検索する
- `rg -n "codeql-action" .github/workflows` CodeQL Actionの利用箇所を検索する
- `rg -n "ui/|resources/|api/" .github/workflows/ci.yml` CI内のパス参照を確認する
- `rg -n "api/|ui/|resources/|scripts/" spot-diggz.code-workspace` Workspace設定内のパス参照を確認する
- `rg -n "api/|ui/|resources/|scripts/" .devcontainer/setup.sh` devcontainerセットアップ内のパス参照を確認する
- `rg -n "api/|ui/|resources/|scripts/" .devcontainer/Dockerfile .devcontainer/devcontainer.json .devcontainer/setup.sh` devcontainer関連のパス参照をまとめて確認する
- `rg -n "api/|ui/|resources/|scripts/" .devcontainer/Dockerfile .devcontainer/devcontainer.json` devcontainerファイル内の旧パス参照を確認する
- `rg -n "api/|ui/|resources/|scripts/|sample/|sdz_seed_spots.sh|firebase.json|firestore.rules|\\.terraform-version|\\.firebaserc|cloudbuild_api.yaml|cloudbuild_ui.yaml" -S .` 移行対象のパス参照を横断検索する
- `rg -n "api/|ui/|resources/|scripts/|sample/|sdz_seed_spots.sh|firebase.json|firestore.rules|\\.terraform-version|\\.firebaserc" -S README.md docs AGENTS.md .github spot-diggz.code-workspace` 主要ファイルのパス参照をまとめて確認する
- `rg -n -P "(?<!web/)api/|(?<!web/)ui/|(?<!web/)resources/|(?<!web/)scripts/|(?<!web/)sample/|(?<!web/)sdz_seed_spots\\.sh|(?<!web/)firebase\\.json|(?<!web/)firestore\\.rules|(?<!web/)\\.terraform-version|(?<!web/)\\.firebaserc" -S --glob '!web/**'` web配下以外に旧パス参照が残っていないか確認する
- `rg -n "api/|ui/|resources/|scripts/|sample/|sdz_seed_spots.sh|firebase.json|firestore.rules|\\.terraform-version|\\.firebaserc" -S --glob '!web/**'` web配下を除外したパス参照をざっくり確認する
- `rg -n "dev-start\\.sh|dev-stop\\.sh" -S .` 開発一括起動スクリプトの参照箇所を確認する
- `rg -n "resources/|api/|ui/|scripts/|sample/|sdz_seed_spots.sh" AGENTS.md` AGENTS.md内の旧パス参照を検索する
- `ls web/resources/cloudbuild/*.yaml` Cloud Buildの設定ファイル一覧を確認する
- `gcloud builds submit --project "sdz-dev" --config web/resources/cloudbuild/cloudbuild_api.yaml --substitutions _PROJECT_ID="sdz-dev",_REGION="asia-northeast1",_STAGE="dev",_API_IMAGE="asia-northeast1-docker.pkg.dev/sdz-dev/sdz-dev-api/sdz-api:latest",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com"` Cloud BuildでAPIのビルド・デプロイを実行する
- `gcloud builds submit --project "sdz-dev" --config web/resources/cloudbuild/cloudbuild_ui.yaml --substitutions _UI_BUCKET="sdz-dev-ui-bucket",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com",_VITE_SDZ_API_URL="https://sdz-dev-api-xxxxx.a.run.app",_VITE_FIREBASE_API_KEY="***",_VITE_FIREBASE_AUTH_DOMAIN="***",_VITE_FIREBASE_PROJECT_ID="sdz-dev"` Cloud BuildでUIのビルド・配信を実行する
- `set -a; source web/ui/.env.local; set +a; gcloud builds submit --project "sdz-dev" --config web/resources/cloudbuild/cloudbuild_ui.yaml --substitutions _UI_BUCKET="sdz-dev-ui-bucket",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com",_VITE_SDZ_API_URL="${VITE_SDZ_API_URL}",_VITE_FIREBASE_API_KEY="${VITE_FIREBASE_API_KEY}",_VITE_FIREBASE_AUTH_DOMAIN="${VITE_FIREBASE_AUTH_DOMAIN}",_VITE_FIREBASE_PROJECT_ID="${VITE_FIREBASE_PROJECT_ID}"` web/ui/.env.local の VITE_* を読み込んでCloud BuildでUIのビルド・配信を実行する
- `rg -n "sdz_seed_spots|seed_spots" -S .` seedスクリプトの参照箇所を検索する
- `trivy fs .` リポジトリ全体の脆弱性/シークレットスキャンを実行する

</details>

## ⚙️ 環境変数（API）

- `web/api/.env.example` をコピーして `web/api/.env` を作成する（秘匿情報はコミットしない）
- `SDZ_AUTH_PROJECT_ID` … Firebase/Identity PlatformのプロジェクトID（例: sdz-dev）
- `SDZ_USE_FIRESTORE` … `1` でFirestore利用、未設定ならインメモリ
- `SDZ_FIRESTORE_PROJECT_ID` … FirestoreのプロジェクトID（省略時はSDZ_AUTH_PROJECT_IDを使用）
- `SDZ_FIRESTORE_TOKEN` … Firestore RESTに使うBearerトークン（`gcloud auth print-access-token` など）
- `SDZ_CORS_ALLOWED_ORIGINS` … カンマ区切りの許可オリジン（未設定時はlocalhost:3000のみ）
- `SDZ_STORAGE_BUCKET` … 画像アップロード先のCloud Storageバケット名
- `SDZ_STORAGE_SERVICE_ACCOUNT_EMAIL` … 署名URL生成に使うサービスアカウントのメール
- `SDZ_STORAGE_SIGNED_URL_EXPIRES_SECS` … 署名URLの有効期限（秒、デフォルト900）
- `SDZ_STORAGE_SIGNING_TOKEN` … 署名URL生成に使うアクセストークン（未設定時はSDZ_FIRESTORE_TOKENやメタデータ経由）
  
UIの環境変数（`VITE_*`）は `web/ui/.env.local` に設定する。例は `docs/DEVELOPMENT_SETUP.md` を参照。

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
