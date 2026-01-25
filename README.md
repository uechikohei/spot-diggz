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
- `gh issue list -R uechikohei/spot-diggz --search "KEYWORD" --state all --limit 10` Issueの重複確認のため検索する
- `gh issue list -R uechikohei/spot-diggz --search "is:open" --limit 50` 未完了Issueを一覧で確認する
- `gh issue list -R uechikohei/spot-diggz --search "iOS is:open" --limit 50 --json number,title,labels,url --jq '.[] | {number,title,labels:[.labels[].name],url}'` iOS関連の未完了IssueをJSONで一覧化する
- `gh issue view ISSUE_NUMBER -R uechikohei/spot-diggz --json title,body,url` Issue本文を取得する
- `gh issue view ISSUE_NUMBER --json number,title,body,labels,state` Issueの概要（番号/本文/ラベル/状態）を確認する
- `gh issue create -R uechikohei/spot-diggz -t \"TITLE\" -b \"BODY\"` Issueを作成する
- `gh issue comment ISSUE_NUMBER -R uechikohei/spot-diggz -b \"BODY\"` Issueに根拠コメントを追加する
- `gh issue close ISSUE_NUMBER -R uechikohei/spot-diggz` IssueをCloseにする
- `gh issue edit ISSUE_NUMBER -R uechikohei/spot-diggz --title \"TITLE\" --body-file PATH` Issueのタイトル/本文を更新する
- `gh issue edit ISSUE_NUMBER -R uechikohei/spot-diggz --body \"BODY\"` Issue本文を直接更新する
- `gh issue edit ISSUE_NUMBER -R uechikohei/spot-diggz --add-label LABEL` Issueにラベルを追加する
- `gh run view RUN_ID -R uechikohei/spot-diggz` GitHub Actionsの実行詳細を確認する
- `gh run view RUN_ID -R uechikohei/spot-diggz --log-failed` 失敗したGitHub Actionsジョブのログを確認する
- `gh label list -R uechikohei/spot-diggz --search planning` planningラベルの有無を検索する
- `gh label create planning -R uechikohei/spot-diggz --color C5DEF5 --description "Planning/設計検討"` planningラベルを作成する
- `gh issue reopen ISSUE_NUMBER -R uechikohei/spot-diggz` Close済みのIssueを再オープンする
- `gh pr create -R uechikohei/spot-diggz -t \"TITLE\" -b \"BODY\"` Pull Requestを作成する
- `gh pr create -R uechikohei/spot-diggz --base develop --head feature/tiddy-repo -t \"TITLE\" -F /tmp/pr-body.md` ベース/ヘッドを指定し、本文をファイルで指定してPull Requestを作成する
- `gh pr create -R uechikohei/spot-diggz --base develop --head hotfix/NAME -t \"TITLE\" -b \"BODY\"` hotfixブランチからdevelop向けのPull Requestを作成する
- `gh pr view PR_NUMBER -R uechikohei/spot-diggz --json title,author,baseRefName,headRefName,state,mergeable,mergeStateStatus,labels,files` Pull Requestの概要と変更ファイルをJSONで確認する
- `gh pr reopen ISSUE_NUMBER -R uechikohei/spot-diggz` Close済みのPull Requestを再オープンする
- `gh pr edit ISSUE_NUMBER -R uechikohei/spot-diggz --base develop` Pull Requestのベースブランチを変更する
- `gh pr merge PR_NUMBER -R uechikohei/spot-diggz --merge` Pull Requestをマージ（merge commit）する
- `gh project field-list 2 --owner uechikohei --format json` Projectのフィールドと選択肢IDを確認する
- `gh project item-add 2 --owner uechikohei --url \"ISSUE_URL\"` IssueをProjectに追加する
- `gh project item-add 2 --owner uechikohei --url \"ISSUE_URL\" --format json` IssueをProjectに追加し、項目IDを取得する
- `gh project item-add 2 --owner uechikohei --url \"ISSUE_URL\" --format json | jq -r '.id'` IssueをProjectに追加して項目IDのみを取得する
- `gh project item-list 2 --owner uechikohei --format json | jq -r '.items[] | select(.content.number==ISSUE_NUMBER) | .id'` Project内のIssue番号から項目IDを取得する
- `gh project item-list 2 --owner uechikohei --limit 200 --format json | jq -r '.items[] | select(.content.number==ISSUE_NUMBER) | .id'` Project内のIssue番号から項目IDを取得する（件数が多い場合）
- `gh project item-edit --project-id PVT_kwHOAx5dHc4BLgT- --id ITEM_ID --field-id PVTSSF_lAHOAx5dHc4BLgT-zg7DwBA --single-select-option-id OPTION_ID` ProjectのPriorityを更新する
- `gh project item-edit --project-id PVT_kwHOAx5dHc4BLgT- --id ITEM_ID --field-id PVTF_lAHOAx5dHc4BLgT-zg7DwBQ --date YYYY-MM-DD` ProjectのStart dateを更新する
- `SDZ_ID_TOKEN=... SDZ_API_URL=... ./web/scripts/firestore_crud_smoke.sh` Firestore実運用のCRUDをAPI経由でスモークテストする（`X-SDZ-Client: ios`付き）
- `SDZ_ID_TOKEN=... SDZ_API_URL=... curl -i -X PATCH "${SDZ_API_URL}/sdz/spots/SPOT_ID" -H "Authorization: Bearer ${SDZ_ID_TOKEN}" -H "Content-Type: application/json" -H "X-SDZ-Client: ios" -d '{"name":"probe"}' | head -n 5` spot更新APIがPATCHを受け付けるか確認する
- `payload=$(jq -n --arg email "${SDZ_TEST_USER_EMAIL}" --arg password "${SDZ_TEST_USER_PASSWORD}" '{email:$email,password:$password,returnSecureToken:true}'); SDZ_ID_TOKEN=$(curl -sS "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${SDZ_FIREBASE_WEB_API_KEY}" -H "Content-Type: application/json" -d "${payload}" | jq -r '.idToken')` Firebase Auth REST APIでIDトークンを取得する
- `date +%Y-%m-%d` 起票日のYYYY-MM-DDを取得する
- `ls` リポジトリ直下のファイル一覧を確認する
- `ls -a` 隠しファイルを含めて一覧を確認する
- `rm iOS/spot-diggz.xcodeproj/project.xcworkspace/xcuserdata/USER.xcuserdatad/UserInterfaceState.xcuserstate` Xcodeのユーザー状態ファイルを削除して追跡解除する
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
- `rg -n "user" web/api/src` API側のユーザー関連実装を横断検索する
- `rg -n "UploadUrl" iOS/spot-diggz` iOSのアップロードURL関連実装を検索する
- `rg -n "XCRemoteSwiftPackageReference" iOS/spot-diggz.xcodeproj/project.pbxproj` iOSプロジェクトのSwift Package参照有無を確認する
- `rg --files -g "GoogleService-Info.plist" iOS` iOS配下にFirebase設定ファイルがあるか確認する
- `rg --files -g "Info.plist" iOS` iOS配下のInfo.plist有無を確認する
- `rg -n "INFOPLIST_FILE" iOS/spot-diggz.xcodeproj/project.pbxproj` iOSプロジェクトのInfo.plist設定有無を確認する
- `rg -n "PBXFileReference" iOS/spot-diggz.xcodeproj/project.pbxproj | head -n 5` XcodeプロジェクトのFileReferenceセクションの有無を簡易確認する
- `rg -n "SdzAppState.swift" iOS/spot-diggz.xcodeproj/project.pbxproj` XcodeプロジェクトにSdzAppState.swiftが参照されているか確認する
- `rg -n "ContentView.swift" iOS/spot-diggz.xcodeproj/project.pbxproj` XcodeプロジェクトにContentView.swiftが参照されているか確認する
- `rg -n "CFBundleURLTypes|URLTypes|URLSchemes" iOS/spot-diggz.xcodeproj/project.pbxproj` URLスキーム設定があるかを確認する
- `rg -n "Firebase" iOS/spot-diggz` iOS実装内のFirebase関連箇所を検索する
- `rg -n "@Published" iOS/spot-diggz` iOS実装内のObservableObject/@Published利用箇所を検索する
- `rg -n "SdzSpotLocation" iOS` iOS内の位置情報モデル参照箇所を検索する
- `rg -n "struct SdzSpotLocation|SdzSpotLocation" iOS/spot-diggz -g "*.swift"` iOSの位置情報構造体定義と参照箇所を確認する
- `rg -n "LocationPicker|Map|Location" iOS/spot-diggz/Presentation iOS/spot-diggz/Data iOS/spot-diggz/Domain` iOSの位置情報/Map関連の利用箇所を横断検索する
- `rg -n "MKLocalSearchCompleter|MKLocalSearch" iOS/spot-diggz/Presentation/Components/SdzLocationPickerView.swift` 位置検索の実装箇所を確認する
- `rg -n "Route|route" iOS/spot-diggz/Presentation iOS/spot-diggz/Domain iOS/spot-diggz/Data` iOSのルート/ナビ関連の実装箇所を横断検索する
- `rg -n "ImagePicker|PhotosPicker|PHPicker" iOS/spot-diggz` iOSの画像選択UI関連の実装箇所を検索する
- `rg -n "drag|drop|onMove|move\\(" iOS/spot-diggz/Presentation` iOSのドラッグ/並び替え関連の実装箇所を検索する
- `rg -n "SdzSpotImageItem|imageItems" iOS/spot-diggz/Presentation/Screens` iOSのスポット画像管理ロジックの実装箇所を検索する
- `rg -n "xcshareddata|Package\\.resolved|xcworkspace" .gitignore` .gitignore内にXcode/SwiftPM関連の除外があるか確認する
- `rg -n "未承認|編集|Edit" iOS/spot-diggz` iOSの編集画面/文言の実装箇所を検索する
- `rg -n "MyList|マイリスト" iOS/spot-diggz` iOSのマイリスト関連実装を検索する
- `rg -n "trustLevel|trustSources|approvalStatus" iOS web/api docs` 承認ステータス関連のフィールド参照箇所を横断検索する
- `rg -n "canRequestApproval|approvalStatus" iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` iOSの承認申請条件と表示ロジックを確認する
- `rg -n "CFBundleURLTypes" ..` リポジトリ配下でURLスキーム設定の痕跡を検索する
- `rg -n "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription" iOS/spot-diggz.xcodeproj/project.pbxproj` 位置情報の利用許可文言設定を確認する
- `rg -n "Cloud Run|cloud run|run.app|ingress|allUsers|iam|invoker" -S web docs .github` Cloud Run公開設定の痕跡をドキュメントと設定で確認する
- `rg -n "^  notify:" .github/workflows/ci.yml` ci.yml内のnotifyジョブ重複を確認する
- `git status -sb` 作業ブランチと差分の概要を確認する
- `git status --short` 変更ファイルを短い形式で確認する
- `git checkout -b BRANCH_NAME` 新しい作業ブランチを作成して切り替える
- `rg -n "cloud_run|run.invoker|allUsers|invoker|ingress" -S web/resources` TerraformのCloud Run公開/IAM設定を確認する
- `rg -n "SdzApiClient|SdzEnvironment|SdzAppState|fetchSpots|fetchSpot" iOS/spot-diggz` iOSのAPI連携関連コードをまとめて検索する
- `rg -n "SdzErrorResponse|API設計" iOS/SDZ_IOS_DESIGN.md` iOS設計書内のAPI/エラーモデル記載を確認する
- `sed -n '30,120p' iOS/SDZ_IOS_DESIGN.md` iOS設計書の画面/ナビゲーション章を確認する
- `sed -n '1,200p' iOS/spot-diggz/Presentation/Components/SdzMapNavigator.swift` iOSのナビ起動ロジックを確認する
- `rg -n "xcodeproj|xcworkspace|xcuserdata" .gitignore` .gitignoreのXcode関連除外設定を確認する
- `rg -n "xcodeproj|xcworkspace|xcuserdata|xcuserstate" .gitignore` .gitignoreのxcuserstate除外有無を確認する
- `rg --files iOS/Data iOS/Domain iOS/Presentation` iOS配下の実装ファイル一覧を確認する
- `rg --files -g "*ImageRow*" iOS/spot-diggz` iOSの画像並び替え関連ファイル名を検索する
- `rg -n "spots" web/api/src/presentation/router.rs` APIルーティングのspots関連エンドポイントを確認する
- `rg -n "CreateSpot" web/api/src` CreateSpot入力/UseCaseの実装箇所を検索する
- `rg -n "new_with_id" web/api/src` SdzSpot生成処理の利用箇所を検索する
- `rg -n "users/me|current user|fetch_current" web/api/src` APIのユーザー取得処理を検索する
- `rg -n "SpotRepository|spot_repo" web/api/src/application` SpotRepositoryの利用箇所を検索する
- `rg -n "mylist" web/api/src` MyList API/リポジトリの実装箇所を検索する
- `rg -n "struct SdzSpot|impl SdzSpot" web/api/src/domain` SdzSpotの定義/実装箇所を検索する
- `rg -n "fn update\\(" web/api/src/domain/models.rs` SdzSpotのupdate実装位置を確認する
- `rg -n "SdzSpotBusinessHours|SpotBusiness" web/api/src/domain/models.rs` 営業時間モデルの定義位置を確認する
- `rg -n "BusinessHours|business_hours|businessHours" web/api/src` API側の営業時間関連実装を横断検索する
- `rg -n "streetAttributes|street_attributes" web/api/src` API側のストリート属性関連実装を検索する
- `rg -n "streetAttributes|street_attributes" web/api iOS` API/iOS両方のストリート属性関連実装を横断検索する
- `rg -n "update_spot|UpdateSpotInput|/sdz/spots" web/api/src/presentation` spots更新ハンドラ/入力の実装箇所を検索する
- `rg -n "createSpot" iOS/spot-diggz/Data/Repositories/SdzApiClient.swift` iOSのspot作成API呼び出し箇所を検索する
- `rg -n "search|filter|タグ|tag" web/ui/src` Web UIの検索/フィルタ実装箇所を検索する
- `rg -n "search|filter|query" web/api/src` API側の検索/フィルタ関連実装を検索する
- `ls web/api/src/presentation/handlers` APIハンドラ一覧を確認する
- `sed -n '1,240p' web/api/src/presentation/router.rs` APIルーティングの詳細を確認する
- `sed -n '1,260p' web/api/src/presentation/handlers/spot_handler.rs` spot APIの入力/認証条件を確認する
- `sed -n '1,200p' web/api/src/presentation/handlers/user_handler.rs` users/me APIの処理概要を確認する
- `sed -n '1,220p' web/api/src/presentation/handlers/mylist_handler.rs` mylist APIの入力/レスポンスを確認する
- `sed -n '1,260p' web/api/src/application/use_cases/create_spot_use_case.rs` CreateSpot入力/バリデーションを確認する
- `sed -n '1,260p' web/api/src/application/use_cases/update_spot_use_case.rs` UpdateSpot入力/承認更新条件を確認する
- `sed -n '1,200p' web/api/src/application/use_cases/list_spots_use_case.rs` 一覧取得の公開/認証条件を確認する
- `sed -n '1,200p' web/api/src/application/use_cases/get_spot_use_case.rs` 詳細取得の公開/認証条件を確認する
- `sed -n '1,160p' web/api/src/application/use_cases/add_mylist_use_case.rs` mylist追加の入力形式を確認する
- `sed -n '1,200p' web/api/src/application/use_cases/generate_upload_url_use_case.rs` upload-urlの入力と拡張子対応を確認する
- `sed -n '1,200p' web/api/src/application/use_cases/storage_repository.rs` upload-urlのレスポンス形式を確認する
- `rg -n "struct SdzSpot|enum SdzSpotApprovalStatus|SdzSpotParkAttributes|SdzStreetAttributes|SdzSpotBusinessHours" web/api/src/domain/models.rs` スポット/属性モデル定義位置を確認する
- `rg -n "validate_spot|images must|MAX_IMAGES" web/api/src/domain/models.rs` スポット入力のバリデーション条件を確認する
- `sed -n '1,200p' web/api/src/domain/models.rs` APIのモデル定義を確認する
- `sed -n '220,340p' web/api/src/domain/models.rs` スポットのバリデーション定義を確認する
- `sed -n '260,520p' web/api/src/infrastructure/firestore_spot_repository.rs` Firestoreのスポット保存マッピングを確認する
- `sed -n '1,200p' web/api/src/presentation/middleware/auth.rs` Authorizationヘッダー仕様を確認する
- `sed -n '1,200p' web/api/src/presentation/middleware/client.rs` X-SDZ-Clientヘッダーの仕様を確認する
- `sed -n '1,200p' web/api/src/presentation/error.rs` APIエラーレスポンスの形式を確認する
- `sed -n '1,260p' iOS/spot-diggz/Data/Repositories/SdzApiClient.swift` iOS側のAPIリクエスト/ヘッダーを確認する
- `sed -n '1,200p' iOS/spot-diggz/Domain/Entities/SdzCreateSpotInput.swift` iOSのスポット作成入力を確認する
- `sed -n '1,220p' iOS/spot-diggz/Domain/Entities/SdzUpdateSpotInput.swift` iOSのスポット更新入力を確認する
- `sed -n '1,220p' iOS/spot-diggz/Domain/Entities/SdzSpot.swift` iOSのスポットモデル定義を確認する
- `sed -n '1,200p' iOS/spot-diggz/Domain/Entities/SdzUser.swift` iOSのユーザーモデル定義を確認する
- `sed -n '1,220p' web/api/src/application/use_cases/update_spot_use_case.rs` spot更新UseCaseの入力/反映ロジックを確認する
- `sed -n '1,200p' web/api/src/domain/models.rs` spot/属性モデルの定義を確認する
- `sed -n '1,120p' web/api/src/infrastructure/firestore_spot_repository.rs` Firestoreへのupsert処理を確認する
- `sed -n '1,140p' iOS/spot-diggz/Data/Repositories/SdzApiClient.swift` iOSのAPIクライアント実装を確認する
- `git diff -- web/api/src/application/use_cases/update_spot_use_case.rs` 更新UseCaseの差分を確認する
- `rg -n "businessHours|scheduleType" web/ui/src` UI側の営業時間/営業形態の実装有無を確認する
- `rg -n "favorite|mylist|list" web/api/src` API側のマイリスト/お気に入り関連の実装を検索する
- `rg -n "SdzSpotImageRow|SdzSpotImageThumbnail|SdzImageDropDelegate" iOS/spot-diggz` iOSの画像並び替えUI実装を検索する
- `rg -n "streetSurface|streetSections|streetAttributes" iOS/spot-diggz` iOSのストリート情報入力/表示実装を検索する
- `rg -n "LongPressGesture|DragGesture|sequenced" iOS/spot-diggz/Presentation/Screens/PostView.swift` iOSの画像並び替え用ジェスチャ実装を検索する
- `rg -n "CLGeocoder|reverseGeocode|regionCode" iOS/spot-diggz/Presentation/Screens/PostView.swift` iOSの位置情報逆ジオコーディング関連の実装箇所を検索する
- `rg -n "IPHONEOS_DEPLOYMENT_TARGET" iOS/spot-diggz.xcodeproj/project.pbxproj` iOSのデプロイ対象バージョン設定を確認する
- `sed -n '380,470p' iOS/spot-diggz/Presentation/Screens/PostView.swift` PostViewの位置情報/タグ関連ロジックを確認する
- `sed -n '880,960p' iOS/spot-diggz/Presentation/Screens/PostView.swift` PostViewの画像選択Coordinator実装を確認する
- `xcrun --show-sdk-path` 現在のCommand Line ToolsのSDKパスを確認する
- `cargo fmt -- --check` Rust APIのフォーマットチェックを行う
- `cargo clippy -- -D warnings` Rust APIのLintをエラーとして実行する
- `cargo test --verbose` Rust APIのユニットテストを実行する
- `cargo build --release --verbose` Rust APIのリリースビルドを実行する
- `npm ci` UIの依存関係をクリーンインストールする
- `npm run lint` UIのESLintを実行する
- `npm run type-check` UIのTypeScript型チェックを実行する
- `npm test -- --coverage --watch=false` UIのユニットテストをカバレッジ付きで実行する
- `npm run build` UIの本番ビルドを作成する
- `terraform fmt -check -recursive` Terraformのフォーマットチェックを行う
- `terraform init -backend=false` Terraformをバックエンドなしで初期化する
- `terraform validate` Terraformの構成検証を行う
- `tfsec .` Terraformのセキュリティチェックを実行する
- `rg -n "Route" iOS/spot-diggz` Route関連実装を検索する
- `rg -n "ルート" iOS/spot-diggz` ルート文言の実装箇所を検索する
- `rg -n "draftPinLocation|handleMapTap|openPostForDraftPin" iOS/spot-diggz/Presentation/Screens/HomeView.swift` HomeViewの地図タップ/下書きピンの処理箇所を検索する
- `rg -n "SdzLocationPickerView" iOS/spot-diggz` 位置選択コンポーネントの参照箇所を検索する
- `rg -n "handleOpenUrl" iOS/spot-diggz/Data/Repositories/SdzAuthService.swift` OAuthの戻りURL処理の実装箇所を確認する
- `rg -n "TabView|images" iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` スポット詳細の画像表示UI実装を確認する
- `rg -n "images\\.first|images\\[0\\]|main" iOS/spot-diggz/Presentation/Components/SpotCardView.swift iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` メイン画像の表示ロジックを検索する
- `rg -n "ImagePicker|maxImages" iOS/spot-diggz` iOSの画像選択UIと枚数制限の実装箇所を確認する
- `rg -n "profile|ユーザー|account|settings" web/ui/src` Web UIのプロフィール/設定関連の実装箇所を検索する
- `rg -n "reset|password" web/ui/src/App.tsx web/ui/src/contexts/AuthProvider.tsx` Web UIのパスワード再設定関連の実装箇所を検索する
- `rg -n --glob "*.css" -- "--" web/ui/src` Web UIのCSS変数（カスタムプロパティ）定義を検索する
- `rg -n "sdz/spots" docs/openapi.yaml` OpenAPI定義内のspotsエンドポイント位置を確認する
- `rg -n "CreateSpotInput" docs/openapi.yaml` OpenAPI定義内のCreateSpotInputスキーマ位置を確認する
- `rg -n "count_image_spots_by_user" web/api` 画像付きスポット上限バリデーションの実装箇所を検索する
- `rg --files -g "*.swift" iOS/spot-diggz/Presentation` iOS Presentation配下のSwiftファイル一覧を確認する
- `rg --files -g "*.rs" web/api/src` Rust API配下のRustソース一覧を確認する
- `rg --files -g "Contents.json" iOS/spot-diggz/Assets.xcassets` iOSアセットカタログ内のContents.jsonを一覧で確認する
- `rg -n "deploy-dev" .github/workflows/ci.yml` CIの開発環境デプロイジョブの定義位置を確認する
- `SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path) && sed -n '1,120p' "$SDK_PATH/System/Library/Frameworks/MapKit.framework/Headers/MKMapItem.h"` MapKitのMKMapItemヘッダを確認する
- `rg -n "toggleFavorite" iOS/spot-diggz` iOSのお気に入り操作の実装箇所を検索する
- `rg -n "SpotCardView.swift" iOS/spot-diggz.xcodeproj/project.pbxproj` XcodeプロジェクトでSpotCardView参照があるか確認する
- `rg -n "HomeView.swift" iOS/spot-diggz.xcodeproj/project.pbxproj` XcodeプロジェクトでHomeView参照があるか確認する
- `rg -n "Agent運用ルール|開発" AGENTS.md` AGENTS.md内の運用ルール位置を確認する
- `rg -n "使うコマンド一覧" README.md` README内のコマンド一覧の位置を確認する
- `rg -n "PBXFileSystemSynchronizedRootGroup" iOS/spot-diggz.xcodeproj/project.pbxproj` Xcodeのファイル同期グループ設定有無を確認する
- `cat README.md` README全体の記載内容を確認する
- `cat -n FILE` 行番号付きでファイル内容を確認する
- `sed -n '1,200p' FILE` ファイルの先頭200行を確認する
- `sed -n '40,120p' FILE` ファイルの40-120行を確認する
- `sed -n '1,220p' FILE` ファイルの先頭220行を確認する
- `sed -n '1,240p' FILE` ファイルの先頭240行を確認する
- `sed -n '1,260p' FILE` ファイルの先頭260行を確認する
- `sed -n 'START,ENDp' FILE` 任意の行範囲でファイル内容を確認する
- `tail -n 40 FILE` ファイル末尾を確認する
- `ls iOS` iOSディレクトリ直下の内容を確認する
- `ls iOS/spot-diggz` iOSアプリ直下のファイル一覧を確認する
- `ls iOS/spot-diggz/spot-diggz` 二重のspot-diggzディレクトリがあるか確認する
- `git add PATH...` コミット対象のファイルをステージする
- `git commit -m "MESSAGE"` ステージ済みの変更をメッセージ付きでコミットする
- `git stash push -m "MESSAGE" -- PATH` 変更ファイルを一時退避して作業ツリーを整理する
- `git update-index --remove -- PATH` 追跡対象ファイルをインデックスから外す
- `git update-index --force-remove -- PATH` 追跡済みファイルを削除扱いでインデックスから外す
- `git switch BRANCH` ブランチを切り替える
- `git branch -d BRANCH` ローカルブランチを削除する（未マージの場合は失敗）
- `git merge --no-ff BRANCH` ブランチをマージしてマージコミットを作成する
- `git push origin BRANCH` 指定ブランチをリモートへプッシュする
- `git push origin --delete BRANCH` リモートブランチを削除する
- `git status -sb` 変更状況と現在ブランチを短く確認する
- `cargo fmt` Rust APIのフォーマットを自動整形する
- `cargo fmt -- --check` Rust APIのフォーマットチェックを行う
- `cargo clippy -- -D warnings` Rust APIのLintを警告で失敗させて実行する
- `cargo test --verbose` Rust APIのユニットテストを詳細ログで実行する
- `cargo build --release --verbose` Rust APIのリリースビルドを詳細ログで実行する
- `npm ci` React UIの依存関係をクリーンインストールする
- `npm run lint` React UIのLintを実行する
- `npm run type-check` React UIの型チェックを実行する
- `npm test -- --coverage --watch=false` React UIのユニットテストをカバレッジ付きで実行する
- `npm run build` React UIの本番ビルドを実行する
- `npm audit` React UIの依存関係の脆弱性を監査する
- `npm audit fix` React UIの依存関係の脆弱性を自動修正する
- `terraform fmt -check -recursive` Terraformのフォーマットチェックを再帰的に実行する
- `terraform init -backend=false` Terraformの初期化をローカル向けに実行する
- `terraform validate` Terraformの構成バリデーションを実行する
- `trivy fs . --format sarif --output trivy-results.sarif` Trivyでリポジトリ全体の脆弱性/シークレットスキャンを行いSARIF出力する
- `docker build -f .devcontainer/Dockerfile .` CIのDockerビルド相当をローカルで実行する
- `set -a; source web/ui/.env.local; set +a; gcloud builds submit --project "sdz-dev" --config web/resources/cloudbuild/cloudbuild_ui.yaml --gcs-source-staging-dir=gs://sdz-dev_cloudbuild/source --substitutions _UI_BUCKET="sdz-dev-ui-bucket",_DEPLOY_SA_RESOURCE="projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com",_VITE_SDZ_API_URL="${VITE_SDZ_API_URL}",_VITE_FIREBASE_API_KEY="${VITE_FIREBASE_API_KEY}",_VITE_FIREBASE_AUTH_DOMAIN="${VITE_FIREBASE_AUTH_DOMAIN}",_VITE_FIREBASE_PROJECT_ID="${VITE_FIREBASE_PROJECT_ID}"` 開発環境のWeb UIをCloud Buildで再デプロイする
- `python3 -c 'from pathlib import Path; path=Path(".github/workflows/ci.yml"); text=path.read_text(); marker="\\n  # 通知\\n"; head,_=text.split(marker,1); notify_block="\\n  # 通知\\n  notify:\\n    name: \\U0001F4E2 Notify Results\\n    runs-on: ubuntu-latest\\n    needs: [rust-ci, react-ci, terraform-ci]\\n    if: always()\\n\\n    steps:\\n      - name: \\U0001F4E2 Notify status\\n        run: |\\n          if [[ \\"${{ needs.rust-ci.result }}\\" == \\"success\\" && \\"${{ needs.react-ci.result }}\\" == \\"success\\" && \\"${{ needs.terraform-ci.result }}\\" == \\"success\\" ]]; then\\n            echo \\"\\u2705 All CI jobs passed successfully!\\"\\n          else\\n            echo \\"\\u274c Some CI jobs failed. Please check the logs.\\"\\n            exit 1\\n          fi\\n"; path.write_text(head+notify_block)'` ci.ymlの通知ジョブ重複を除去して末尾を整理する
- `git fetch origin` リモートの最新情報を取得する
- `git merge origin/develop` developの変更を取り込み、競合を解消する
- `git switch develop` developブランチへ切り替える
- `git switch master` masterブランチへ切り替える
- `rg -n "streetAttributes|street_attributes|SdzStreet" iOS/spot-diggz` iOSのストリート属性モデル/参照箇所を検索する
- `rg -n "street_attributes|park_attributes|approval_status" web/api/src` API側の承認/属性フィールド参照箇所を検索する
- `rg -n "serde\\(|rename_all|approval_status|street_attributes" web/api/src/presentation web/api/src/domain/models.rs` serdeのrename設定と承認/ストリート属性定義を確認する
- `rg -n "SpotResponse|sdz_spot|ListSpot" web/api/src/presentation` spotハンドラ/レスポンス関連の実装を検索する
- `rg -n "validate_spot|SdzSpotValidation" web/api/src/domain` スポット検証ロジックの位置を確認する
- `rg -n "EditSpotView" -S iOS/spot-diggz` iOS編集画面の参照箇所を検索する
- `rg -n "fetchSpots|spots" iOS/spot-diggz/Presentation/Screens` iOS画面のスポット取得処理を検索する
- `rg -n "fetchSpots" iOS/spot-diggz` iOS全体でスポット取得処理の参照箇所を検索する
- `rg -n "search|filter|タグ|tag|type|spotType" iOS/spot-diggz/Presentation` iOSの検索/フィルタ/種別UI実装を検索する
- `rg -n "SdzSpotCategory|spotType|SpotType" iOS/spot-diggz/Domain iOS/spot-diggz/Presentation` iOSの種別定義と参照箇所を検索する
- `rg -n "SdzSpotSearchQuery|fetchSpots\\(query|queryItems" iOS/spot-diggz` iOSの検索クエリ生成/利用箇所を検索する
- `rg -n "search|filter|tag|type" web/ui/src` Web UIの検索/フィルタ実装箇所を検索する
- `rg -n "q=|type=|tags=|searchParams|URLSearchParams|fetchSpots" web/ui/src/App.tsx` Web UIの検索パラメータ組み立て/取得処理を確認する
- `rg -n "handleResetFilters" web/ui/src/App.tsx` Web UIのフィルタリセット処理を検索する
- `rg -n "SdzSpotListQuery|spot_type|q|tags" web/api/src/presentation/handlers/spot_handler.rs` APIのスポット一覧クエリ定義/処理箇所を確認する
- `rg -n "SpotSearchFilter|spot_type|tags|query" web/api/src/application/use_cases/list_spots_use_case.rs` APIのスポット検索フィルタ実装箇所を確認する
- `sed -n '1,200p' iOS/spot-diggz/Domain/Entities/SdzSpot.swift` iOSスポットモデル定義を確認する
- `sed -n '1,120p' iOS/spot-diggz/Domain/Entities/SdzSpotSearchQuery.swift` iOS検索クエリ定義を確認する
- `sed -n '1,220p' web/api/src/domain/models.rs` APIドメインモデルの定義を確認する
- `sed -n '220,320p' web/api/src/domain/models.rs` スポット検証ロジックの詳細を確認する
- `sed -n '110,220p' web/api/src/application/use_cases/list_spots_use_case.rs` APIのスポット一覧フィルタ実装を確認する
- `sed -n '220,420p' web/api/src/application/use_cases/list_spots_use_case.rs` APIのスポット一覧テストを確認する
- `sed -n '20,160p' web/api/src/presentation/handlers/spot_handler.rs` APIのスポット一覧ハンドラ/クエリ処理を確認する
- `sed -n '260,380p' web/ui/src/App.tsx` Web UIの検索/取得処理周辺を確認する
- `sed -n '1,220p' iOS/spot-diggz/Data/Repositories/SdzApiClient.swift` iOSのAPIクライアント実装を確認する
- `sed -n '1,120p' iOS/spot-diggz/Data/Repositories/SdzApiClient.swift` iOSのAPIクライアント冒頭実装を確認する
- `sed -n '220,420p' iOS/spot-diggz/Data/Repositories/SdzApiClient.swift` iOSのAPIクライアント共通処理を確認する
- `sed -n '1,240p' iOS/spot-diggz/Presentation/Screens/EditSpotView.swift` 編集画面の初期化/フォーム構成を確認する
- `sed -n '240,420p' iOS/spot-diggz/Presentation/Screens/EditSpotView.swift` 編集画面の入力フォームと保存処理前半を確認する
- `sed -n '480,620p' iOS/spot-diggz/Presentation/Screens/EditSpotView.swift` 編集画面のストリート属性生成と検証を確認する
- `sed -n '60,140p' iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` 詳細画面の概要表示と属性セクションを確認する
- `sed -n '300,380p' README.md` README内のコマンド一覧周辺を確認する
- `sed -n '160,220p' iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` 詳細画面の編集/アクション導線を確認する
- `sed -n '220,520p' iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` 詳細画面の属性表示と申請処理を確認する
- `sed -n '520,760p' iOS/spot-diggz/Presentation/Screens/SpotDetailView.swift` 詳細画面のナビ/Instagram連携処理を確認する
- `sed -n '1,120p' iOS/spot-diggz/Presentation/Screens/HomeView.swift` ホーム画面の地図/検索UI構成を確認する
- `sed -n '480,560p' iOS/spot-diggz/Presentation/Screens/HomeView.swift` ホーム画面のスポット取得処理を確認する
- `sed -n '240,340p' web/api/src/infrastructure/firestore_spot_repository.rs` Firestoreのスポットフィールド定義を確認する
- `sed -n '500,620p' web/api/src/infrastructure/firestore_spot_repository.rs` Firestoreのスポット属性読み取り処理を確認する
- `sed -n '820,900p' web/api/src/infrastructure/firestore_spot_repository.rs` Firestoreのストリート属性構築処理を確認する
- `sed -n '900,980p' web/api/src/infrastructure/firestore_spot_repository.rs` Firestoreのストリートセクション構築詳細を確認する
- `sed -n '1,220p' web/api/src/presentation/handlers/spot_handler.rs` spotハンドラの入出力処理を確認する
- `sed -n '1,220p' web/api/src/application/use_cases/update_spot_use_case.rs` スポット更新ユースケースの入力処理を確認する
- `git switch feature/NAME` 既存のfeatureブランチへ切り替える
- `git pull --ff-only` リモート更新をfast-forwardで取り込む
- `git merge develop` developの変更をmasterへ取り込む
- `git tag -a v0.1.0-web-mvp -m "web mvp dev release"` web版MVPのリリースタグを作成する
- `git switch -c feature/NAME` featureブランチを作成して切り替える
- `git switch -c hotfix/NAME` hotfixブランチを作成して切り替える
- `git add README.md` READMEの変更のみをステージする
- `git add PATH` 指定ファイルをステージする
- `git add -A` 変更の追加・削除をまとめてステージする
- `git rm -r PATH` 指定ディレクトリ配下のファイルを削除してステージする
- `git diff FILE` 指定ファイルの差分を確認する
- `git diff --name-only origin/develop -- PATH` developとの差分ファイル一覧をパス指定で確認する
- `git show origin/develop:PATH` origin/develop上の特定ファイル内容を確認する
- `git commit -m "MESSAGE"` 変更内容をコミットする
- `git commit --amend` 直前のコミット内容を修正する
- `git stash push -m "MESSAGE"` 作業中の変更をスタッシュへ退避する
- `git stash push -u -m "MESSAGE"` 未追跡ファイルも含めてスタッシュへ退避する
- `git stash list` 退避済みのスタッシュ一覧を確認する
- `git stash pop` 退避した変更を作業ツリーへ戻す
- `git stash apply STASH_REF` 指定したスタッシュを作業ツリーへ適用する
- `git branch -m NEW_NAME` 現在のブランチ名を変更する
- `git push --force-with-lease` リモートの最新を確認した上で履歴を書き換えてpushする
- `git push` 現在のブランチを追跡先へpushする
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
- `mv SOURCE DEST` ファイル/ディレクトリを移動する
- `rm PATH` 指定したファイルを削除する
- `rmdir DIR` 空のディレクトリを削除する
- `curl -sS -o /dev/null -w "%{http_code}\n" "URL"` APIのHTTPステータスだけを確認する
- `curl -sS "URL" | head -c 200` APIレスポンスの先頭を確認する
- `gcloud run services describe sdz-dev-api --region asia-northeast1 --project sdz-dev --format "yaml(spec.template.spec.containers[0].env)"` Cloud Runの環境変数を確認する
- `gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="sdz-dev-api" AND (textPayload:"SDZ_USE_FIRESTORE" OR textPayload:"Firestore")' --project sdz-dev --limit 50 --format "value(textPayload)"` Cloud RunのFirestore関連ログを確認する
- `gcloud logging read 'resource.type="firestore_database" AND protoPayload.serviceName="firestore.googleapis.com" AND (protoPayload.methodName="google.firestore.v1.Firestore.DeleteDocument" OR protoPayload.methodName="google.firestore.v1.Firestore.BatchWrite")' --project sdz-dev --limit 50 --format "table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.methodName, protoPayload.resourceName)"` Firestoreの削除操作ログ（Data Access）を確認する
- `gcloud builds triggers list --project sdz-dev --format "table(id,name,github.owner,github.name,github.push.branch,status)"` Cloud Buildのトリガー一覧を確認する
- `gcloud builds list --project sdz-dev --limit 10 --format "table(id,createTime,status,source.repoSource.repoName,source.repoSource.branchName)"` Cloud Buildの直近ビルド履歴を確認する
- `gcloud builds describe BUILD_ID --project sdz-dev --format "yaml(steps,substitutions)"` Cloud Buildの実行ステップと置換変数を確認する
- `rg --files .github/workflows` GitHub Actionsのワークフローファイルを列挙する
- `gh run list --workflow ci.yml --branch develop --limit 1` developブランチの最新CI実行を確認する
- `gh run watch RUN_ID` 指定したActions実行をウォッチする
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
