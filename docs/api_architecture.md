# spot-diggz API アーキテクチャ計画

## STAR: API開発の目的と狙い
### Situation
- Rustスクラッチ実装でCloud Run上にデプロイするマイクロサービスを構築する計画がある。
- 既存Rails版のAPIは機能が肥大化しメンテナンスが困難だった。
### Task
- 高可用性かつセキュアなREST APIを設計し、Web/モバイル双方からのアクセスを支える共通基盤を整える。
- 位置情報投稿や画像ハンドリングといった高負荷処理にも対応できる構成を準備する。
### Action
- 非同期ランタイム（Tokio）とHTTPレイヤー（hyper或いはaxum相当の薄いルータ）を採用したレイヤードアーキテクチャを定義する。
- 認証／認可、スポット管理、ユーザー管理、統合メトリクスの各コンポーネントを明確に分離し、FirestoreやCloud Storageと疎結合に連携する。
### Result
- iOSアプリやWebフロントが同一APIを利用でき、将来的な機能拡張にも耐える保守性の高い基盤が整う。

## STAR: Rust APIモジュール構成計画
### Situation
- モノレポ内でRust APIを`src/api`配下に配置するが、ディレクトリ構成やモジュール命名が未定。
- 認証やデータアクセスなど横断的関心事を分離しないと複雑化が懸念される。
### Task
- クリーンなレイヤー分割（presentation / application / domain / infrastructure）をRustらしく実現する。
- sdzプレフィックス命名規約に従い、一貫性のあるモジュール名・構造体名を定義する。
### Action
- ルータ層: `sdz_router.rs`でエンドポイントを定義し、モジュールごとにハンドラを分割。
- アプリ層: `sdz_usecases`ディレクトリにユースケース単位のサービス（例: `sdz_spot_service.rs`）を配置。
- ドメイン層: エンティティや値オブジェクトを`sdz_models.rs`等にまとめ、バリューの検証を担う。
- インフラ層: Firestoreクライアント、Cloud Storageアップローダ、地図API連携クライアントなどを`infrastructure/`配下に実装。
### Result
- モジュールの責務が明確になり、テスト・Mockの分離が容易になる。CI/CDでのコンパイル時間や可観測性も改善が見込まれる。

## 5W1H: Rust APIプロジェクト初期構成
- **Who**: バックエンド担当（Rust習熟を目指す開発者）が中心、iOS/フロントチームもAPI契約を参照。
- **What**: `src/api`配下に以下の主要構成を作成。`Cargo.toml`でTokio・hyper/h3・serdeなどを管理。
  - `src/main.rs`（エントリポイント、`sdz_bootstrap.rs`へ委譲）
  - `sdz_bootstrap.rs`（設定ロード、DI、サーバー起動）
  - `presentation/sdz_router.rs`（ルーティング定義）
  - `presentation/handlers/`（`sdz_auth_handler.rs`, `sdz_spot_handler.rs`, `sdz_user_handler.rs`）
  - `application/sdz_usecases/`（ユースケースロジック）
  - `domain/`（`sdz_models.rs`, `sdz_value_objects.rs`）
  - `infrastructure/`（`sdz_firestore_repository.rs`, `sdz_storage_client.rs`, `sdz_mapkit_gateway.rs` など）
- **When**: Phase 1の基盤構築でディレクトリと雛形を整備し、Phase 2で各ユースケースを実装。
- **Where**: Gitモノレポ内の`src/api`ディレクトリ、およびCloud Runデプロイパイプライン（Cloud Build）。
- **Why**: レイヤー分離により認証、スポット管理、外部API連携を疎結合化し、テスト容易性とセキュリティ制御を高めるため。
- **How**: Configは`sdz_config`モジュールで環境変数（Secret Manager連携）を読み込み、依存注入は構造体パターンで実施。FireStoreアクセスは`google-cloud-firestore`互換クライアント、MapKit/Google Maps連携はREST/gRPCクライアントを用意する。

## 5W1H: 投稿APIと位置情報連携のトラブル観点
- **Who**: 投稿するのは認証済み会員ユーザー。iOSアプリからの投稿が主だがWeb管理画面も想定。
- **What**: `POST /v1/sdz-spots`で座標・画像・タグを受け取り、Firestoreに保存しCloud Storageへ画像を転送。MapKit経由の経路提案情報はメタデータとして保持。
- **When**: 投稿時に端末位置情報と撮影タイミングを同時取得。エラーは即時フィードバックし、再試行ポリシーを定める。
- **Where**: クライアントはiOSアプリ（オフライン対応あり）とブラウザ。サーバー側はCloud Run内のRust API、データはFirestore/Storage。
- **Why**: コミュニティ主導でスポット情報を充実させ、ナビ機能と連携した価値を提供するため。
- **How**: JWT（Firebase Auth予定）で認証。リクエスト検証→ユースケース→リポジトリ→Firestore書込み→イベント発行（Pub/Subでレコメンド更新）。失敗時はIdempotency-Keyを利用し重複投稿を防ぐ。

## 次アクションの指針
- Phase 1では`src/api`のディレクトリ雛形とConfig/Routerの基礎コードを作成し、CIでビルドと`cargo fmt`を整備。
- 認証・ユーザー・スポットのREST契約（OpenAPIまたはAsyncAPI）を定義し、iOS/フロントと契約テストを合意。
- MapKit/Google Maps連携のPoC（ルート生成と共有リンク）をRust側のGatewayモジュールで検証する。***
