# Rust API レイヤー構成メモ

## なぜレイヤー分割するのか (Why)
- 認証やルーティング、データ保存などの関心事を分離し、変更に強い構造を保つため。
- Webクライアント・iOSクライアントなど複数チャネルからの利用を想定し、ビジネスロジックを共通化するため。
- テスト対象の粒度を明確にし、ユニットテストやモック注入を行いやすくするため。

## REST APIとの関係 (Relation to REST)
- エンドポイント構成やHTTPメソッド利用は一般的なREST APIと同じ。`GET /sdz/health`のようにURLでリソースを表現する。
- 違いは、Rustでの実装をクリーンアーキテクチャ風にレイヤー化している点。DjangoやRailsでもMVCがあるように、Rustでも役割を分けているだけ。
- Cloud Runなどサーバーレス環境でも、入口（ルーター）→ユースケース→リポジトリ→データストアという流れは共通。

## レイヤーの役割 (What)
| レイヤー | 役割 | 主なファイル例 |
|----------|------|----------------|
| presentation | HTTPリクエスト/レスポンス処理、ルーティング | `presentation/sdz_router.rs`, `presentation/handlers/sdz_health_handler.rs` |
| application | ユースケースの調停役。ドメインを呼び出し、外部サービスを統合 | `application/sdz_usecases/sdz_health_check_usecase.rs` |
| domain | ビジネスルールやエンティティ、値オブジェクトを表現 | `domain/sdz_models.rs` |
| infrastructure | FirestoreやCloud Storage、外部APIとの通信実装 | `infrastructure/`配下に今後追加 |

## bootstrapの役割 (How)
- `sdz_bootstrap.rs`はアプリ起動時の初期化専用モジュール。サーバーのポート解決、Routerの組み立て、依存関係の注入をまとめる。
- UIというよりは、サーバーのエントリポイント近くの設定係。DjangoやFastAPIでいう「app = FastAPI()」「uvicorn.run(...)」をひとまとめにしたイメージ。
- 将来的にConfig読み込みやログ設定、DIコンテナ初期化などもここに集約すると整頓しやすい。

## ディレクトリ構成 (Where)
```
src/api/
  ├── src/
  │   ├── main.rs            // Tokioエントリポイント
  │   ├── sdz_bootstrap.rs   // サーバー起動処理
  │   ├── presentation/      // ルーターとハンドラ
  │   ├── application/       // ユースケース
  │   ├── domain/            // ドメインモデル
  │   └── infrastructure/    // Firestore等の実装予定
  └── Cargo.toml
```

## 処理の流れ (Flow)
1. `main.rs` → `sdz_bootstrap::sdz_bootstrap()`を呼ぶ。
2. bootstrapがPORT環境変数を読み出し、hyperサーバーを起動。
3. リクエストが来ると`presentation::sdz_router`がURL/HTTPメソッドでマッチング。
4. ハンドラが`application`レイヤーのユースケースを呼び出す。
5. ユースケースが必要に応じて`domain`エンティティを操作し、`infrastructure`のリポジトリでFirestore等にアクセス。
6. 結果をJSON化してレスポンスとして返す。

## Python/AWSとの比較 (Learning)
- FastAPI + SQLAlchemyなどでよく見る「Router → Service → Repository」構造とほぼ同じ。Rustでは命名が違うだけ。
- AWS API Gatewayを利用する場合でも、Lambda内部の処理は同様にレイヤー化できる。Gatewayが`presentation`相当を担当し、内部コードが`application`以降を担うイメージ。
- Rustでは所有権や非同期処理の制約があるため、レイヤー間でデータを受け渡す際にライフタイムやSend/Sync境界を意識する必要がある。

## Cloud RunとAPI Gateway/Lambdaの責務比較 (Context)
- **インバウンドの受付**: API GatewayやALBが行っていたリクエスト受付・ルーティングは、Cloud Runの場合コンテナに直接届く。必要に応じてCloud Load Balancing + Cloud Run、またはCloud Endpoints/API Gateway + Cloud Runを組み合わせてフロントを作れる。
- **スロットリング/リクエスト制御**: AWS API Gatewayのレート制限やWAFに相当するものは、Cloud Armor（WAF）やService Control Policies、Cloud Runの同時実行数制限で代替する。アプリ側でも`application`レイヤーにRate Limiterを実装可能。
- **認証**: API Gatewayが提供する署名検証は、Cloud RunではIdentity Platform、IAP、またはアプリ内JWT検証で担保する。`presentation`層のミドルウェアで検証し、`application`層に認可ロジックを渡す構成が典型。
- **スケーリング**: Lambdaはイベント駆動で自動スケールするが、Cloud Runもリクエスト数に応じてコンテナを自動スケールし、最大同時実行数で平準化する。Rustコンテナ内での処理はコンテナ上で完結するため、APIGateway→Lambdaの二段構えではなく「Load Balancer/Identity層 → Cloud Runコンテナ → Rustアプリ」というシンプルなラインになる。
- **アプリ内の責務**: API Gatewayが担っていた前処理が減るぶん、Rust側の`presentation`や`application`レイヤーで認証・入力検証・制限ロジックを明示的に実装する必要がある。これにより制御が明確になる一方、テストも増えるのでIaCで周辺サービス設定を補うのが望ましい。

## 今後学ぶポイント (Next)
- `infrastructure`レイヤーでFirestore/Cloud Storageクライアントを実装する際の非同期エラーハンドリング。
- `application`レイヤーでトランザクションや複数リポジトリを組み合わせるパターン。
- `domain`でバリデーションロジックやビジネスルールを表現するテクニック（Smart Constructorなど）。
- `presentation`でミドルウェア（認証、ロギング、Rate Limiting）を実装する方法。
