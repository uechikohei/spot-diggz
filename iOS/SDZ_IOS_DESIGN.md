# spot-diggz iOS 設計書

## 0. 概要
- 目的: 既存Rust APIに接続するiOSアプリの設計を確定し、Xcode実装を継続可能にする。
- 対象: iOSネイティブアプリ（Swift/SwiftUI + Firebase Auth + MapKit）。
- スコープ: スポット一覧/詳細/投稿（画像アップロード含む）/認証/プロフィール/お気に入り。

## 1. 参照
- `docs/spot_diggz_overview.md` (iOS想定/マルチチャネル方針)
- `docs/api_architecture.md` (API方針/認証方針)
- `docs/openapi.yaml` (API契約)
- `web/ui/src/App.tsx` (WebのUI/UXとAPI呼び出し)
- `web/ui/src/contexts/AuthProvider.tsx` (Firebase Authフロー/ユーザードキュメント作成)
- `web/ui/src/firebase.ts` (Firebase設定)
- `web/ui/src/types/spot.ts` (Spot型定義)
- `web/ui/.env` / `web/ui/.env.local` (API Base/Firebase設定値)
- `web/api/src/presentation/router.rs` (ルーティング)
- `web/api/src/presentation/middleware/auth.rs` (JWT検証)
- `web/api/src/presentation/middleware/client.rs` (X-SDZ-Client必須)
- `web/api/src/presentation/handlers/spot_handler.rs` (投稿/一覧/詳細)
- `web/api/src/presentation/handlers/user_handler.rs` (プロフィール取得)
- `web/api/src/presentation/error.rs` (エラーレスポンス)
- `web/api/src/application/use_cases/create_spot_use_case.rs` (入力検証)
- `web/api/src/application/use_cases/generate_upload_url_use_case.rs` (画像アップロード仕様)
- `web/api/src/domain/models.rs` (サーバー側モデル)
- `web/api/src/infrastructure/storage_signed_url_repository.rs` (Signed URLはPUT)
- `web/scripts/firestore_crud_smoke.sh` (ヘッダ/投稿リクエスト例)

## 2. 全体アーキテクチャとiOSの役割
### 2.1 位置付け
```
[iOS SwiftUI] -> [SdzApiClient] -> [Rust API] -> [Firestore/Cloud Storage]
                      |
                      +-> [Firebase Auth] (IDトークン発行)
```

### 2.2 役割
- iOSは「投稿/ナビ/現地利用」を強化したクライアント。
- Webは「閲覧中心」、iOSは「投稿・位置情報連携中心」を想定。
- APIは共通で、iOSはモバイル専用エンドポイントを利用可能。

## 3. iOSアプリの機能要件
### 3.1 コア機能
- スポット一覧（GET /sdz/spots）
- スポット詳細（GET /sdz/spots/{spot_id}）
- スポット投稿（POST /sdz/spots）※認証必須 + `X-SDZ-Client: ios`
- 画像アップロード（POST /sdz/spots/upload-url → PUT Signed URL）
- プロフィール表示（GET /sdz/users/me）
- お気に入り管理（端末ローカル保持）

### 3.2 追加価値（iOS特化）
- MapKit表示、現在地連動、スポットピン表示
- 位置検索/逆ジオコーディングで投稿支援
- Apple Maps/Google Mapsへの外部ナビ連携

## 4. 画面設計とナビゲーション
### 4.1 画面一覧
- 起動画面
- 認証（ログイン/新規登録）
- ホーム（一覧 + 検索/タグ）
- スポット詳細
- マップ
- 投稿（フォーム + 画像 + 位置）
- プロフィール（自分の投稿/お気に入り）

### 4.2 ナビゲーション構成（案）
- Tab Bar
  - Home: 一覧/検索
  - Map: 地図とピン
  - Post: 投稿フロー
  - Profile: ユーザー/お気に入り

### 4.3 主要画面の状態
- 一覧: loading / empty / error / results
- 詳細: loading / not found / error / results
- 投稿: draft / uploading / submitted / error
- 認証: unauthenticated / authenticated / error

## 5. アプリケーションアーキテクチャ
### 5.1 レイヤ構成
- Presentation: SwiftUI + ViewModel (状態管理とUI)
- Domain: UseCase, Entity, Validation
- Data: Repository, DataSource (API/Firebase)
- Infra: URLSession, Firebase SDK, MapKit, CoreLocation

### 5.2 ディレクトリ構成（案）
```
iOS/
  SpotDiggz/
    App/
      SdzApp.swift
      SdzEnvironment.swift
    Presentation/
      Screens/
      Components/
      ViewModels/
    Domain/
      Entities/
      UseCases/
      Validators/
    Data/
      Repositories/
      DataSources/
    Infrastructure/
      API/
      Firebase/
      Location/
    Resources/
      Assets.xcassets
      Localizable.strings
```

### 5.3 命名規約
- Swiftの型/機能名は `Sdz` プレフィックスを推奨（例: `SdzSpot`, `SdzApiClient`）。
- JSONキーはOpenAPIに準拠（camelCase）。

## 6. データモデル設計（Swift）
### 6.1 APIモデル
```swift
struct SdzSpotLocation: Codable {
    let lat: Double
    let lng: Double
}

enum SdzSpotTrustLevel: String, Codable {
    case verified
    case unverified
}

struct SdzSpot: Codable, Identifiable {
    let spotId: String
    let name: String
    let description: String?
    let location: SdzSpotLocation?
    let tags: [String]
    let images: [String]
    let trustLevel: SdzSpotTrustLevel
    let trustSources: [String]?
    let userId: String
    let createdAt: Date
    let updatedAt: Date

    var id: String { spotId }
}

struct SdzUser: Codable {
    let userId: String
    let displayName: String
    let email: String?
}

struct SdzCreateSpotInput: Codable {
    let name: String
    let description: String?
    let location: SdzSpotLocation?
    let tags: [String]?
    let images: [String]?
}

struct SdzUploadUrlRequest: Codable {
    let contentType: String
}

struct SdzUploadUrlResponse: Codable {
    let uploadUrl: String
    let objectUrl: String
    let objectName: String
    let expiresAt: Date
}

struct SdzErrorResponse: Codable, Error {
    let code: Int
    let errorCode: String
    let message: String
}
```

### 6.2 日付デコード方針
- APIの日時はRFC3339（JST +09:00）で返るため、`ISO8601DateFormatter` を使用。
- 例: `JSONDecoder.dateDecodingStrategy = .iso8601`。

## 7. API設計（iOS向け）
### 7.1 共通ヘッダ
- `Authorization: Bearer <Firebase ID Token>`（認証必須エンドポイントのみ）
- `X-SDZ-Client: ios`（モバイル専用エンドポイント）

### 7.2 エンドポイント一覧
| Method | Path | Auth | Client Header | 用途 |
| --- | --- | --- | --- | --- |
| GET | `/sdz/health` | No | No | ヘルスチェック |
| GET | `/sdz/spots` | No | No | 一覧取得 |
| GET | `/sdz/spots/{spot_id}` | No | No | 詳細取得 |
| POST | `/sdz/spots` | Yes | Yes | スポット投稿 |
| POST | `/sdz/spots/upload-url` | Yes | Yes | 画像アップロードURL取得 |
| GET | `/sdz/users/me` | Yes | No | プロフィール取得 |

### 7.3 バリデーション制約（サーバー側）
- `name` 必須
- `location.lat` は -90〜90
- `location.lng` は -180〜180
- `tags` は最大10件
- `images` は最大10件

## 8. 認証設計（Firebase Auth）
### 8.1 サインイン手段
- Email/Password
- Google（Firebase Auth + Google Sign-In）
- Apple（Firebase Auth + Sign in with Apple）

### 8.2 トークン取得
- `Auth.auth().currentUser?.getIDToken()` で毎リクエスト取得。
- 401時はトークンリフレッシュ→再試行を1回のみ許可。

### 8.3 Firestoreユーザードキュメント作成
- Webと同様、ログイン直後に `users/{uid}` を作成/更新。
- 必須フィールド: `email`（Firestore側で`displayName`が未設定だとAPIは`unknown`を返す）。
- 推奨: `displayName`, `createdAt`, `updatedAt` をセット。

## 9. 画像アップロード設計
### 9.1 フロー
1. `POST /sdz/spots/upload-url` に `contentType` を送信。
2. レスポンスの `uploadUrl` へ `PUT` で画像バイナリを送信。
3. `objectUrl` を `CreateSpotInput.images` に追加し、`POST /sdz/spots` 実行。

### 9.2 Content-Type対応
- `image/jpeg`, `image/jpg`, `image/png`, `image/webp`, `image/gif`, `image/heic`, `image/heif`

### 9.3 アップロード時の注意点
- `PUT` の `Content-Type` を必ず一致させる。
- 失敗時はその画像だけ再試行可能にする。

## 10. 位置情報/MapKit設計
### 10.1 位置情報取得
- `CLLocationManager` を使用（`when-in-use`）。
- 位置情報の許可がない場合はMapのみ閲覧可。

### 10.2 Map表示
- `Map` (SwiftUI) / `MKMapView` を利用。
- スポットはピン表示、タップで詳細へ遷移。

### 10.3 投稿時の位置入力
- 現在地 or 検索による位置指定。
- `CLGeocoder` で住所取得し、UIに補助表示。

## 11. ローカル保持/キャッシュ
- お気に入り: `UserDefaults` にspotId配列を保存。
- 一覧キャッシュ: メモリキャッシュ（初期は不要なら未実装）。
- 画像キャッシュ: `URLCache` / `AsyncImage` を利用。

## 12. エラーハンドリング
- APIエラーは `SdzErrorResponse` に変換。
- 401: 再ログイン誘導
- 403: 「モバイル専用」メッセージ
- 404: 「存在しないスポット」表示
- 500: 汎用エラー

## 13. 環境設定（Xcode）
### 13.1 Build Config
- Debug / Release に加え `Dev/Stg/Prod` を推奨。
- `SdzEnvironment` でAPI Baseを切替。

### 13.2 主要設定値
- API Base: `http://localhost:8080` (ローカル), `https://sdz-dev-api-...run.app` (dev)
- Firebase: `GoogleService-Info.plist` を環境別に切替。

### 13.3 Info.plist 必須項目
- `NSLocationWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- ローカルHTTP用のATS例外（必要時のみ）

## 14. テスト方針
- APIクライアント: `URLProtocol` モックでユニットテスト。
- ViewModel: 状態遷移のテスト。
- UIテスト: ログイン/投稿/一覧表示のスモーク。

## 15. 未決定/今後の検討
- お気に入りのサーバー同期有無
- 投稿時のオフラインキュー
- 画像の圧縮/リサイズ方針
- Verifiedスポット昇格フロー（trustLevel/ trustSourcesのUI）
