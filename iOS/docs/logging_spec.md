# SDZログ仕様（共通）

spot-diggz 全体（API / Web UI / iOS / Android）で共通化するログ仕様を定義する。
公開用ではなく内部向け運用資料として扱う。

## 目的
- どのクライアントからのリクエストかを追跡できるようにする
- request_id で API とクライアントのログを相関できるようにする
- エラーの種類と原因を event_code / error_code で統一できるようにする

## ログレベル指針
- INFO: 正常系の重要イベント（認証成功、投稿成功など）
- WARN: 期待外だが復旧可能（認証失敗、入力不正など）
- ERROR: 復旧不能または重要な失敗（500、外部API失敗など）

## 共通フィールド（必須）
- `timestamp`: ISO8601
- `level`: INFO/WARN/ERROR/DEBUG
- `component`: api/ui/ios/android など
- `event_code`: SDZ-API-xxxx / SDZ-UI-xxxx など
- `message`: human readable
- `request_id`: APIで発行したIDをクライアントにも引き回す

## 推奨フィールド
- `user_id`: Firebase UID（取得可能な範囲）
- `status`: HTTP status や処理結果
- `latency_ms`: API処理時間
- `client`: web/ios/android
- `method`: HTTP method
- `path`: API path

## request_id の運用
- API側が `X-Request-Id` を発行しレスポンスに返す
- クライアント側は `X-Request-Id` をログに含める
- API再呼び出し時は `X-Request-Id` を引き継ぐ

## event_code / error_code ルール
- event_code: `SDZ-API-xxxx` / `SDZ-UI-xxxx` / `SDZ-IOS-xxxx` / `SDZ-ANDROID-xxxx`
- error_code: `SDZ-E-xxxx`（HTTPステータス分類と対応）

### 例
- `SDZ-API-2001`: POST /sdz/spots 受付
- `SDZ-API-2002`: spot 作成成功
- `SDZ-API-4010`: 認証失敗
- `SDZ-API-5000`: 予期しない内部エラー

## マスキング方針（PII）
- email / token / address / phone などはマスクする
- 例: `user@example.com` -> `u***@example.com`
- トークンは先頭/末尾のみ表示（`abc...xyz`）

## ログ出力形式（JSON推奨）
```json
{
  "timestamp": "2025-12-31T08:55:09.359511Z",
  "level": "INFO",
  "component": "api",
  "event_code": "SDZ-API-2002",
  "message": "spot created",
  "request_id": "xxxx-xxxx",
  "user_id": "uid-xxx",
  "status": "200 OK",
  "latency_ms": 121
}
```

## クライアント別の注意点
### Web UI
- ユーザー操作（ログイン、一覧取得、詳細表示）を INFO で記録
- API失敗時は WARN/ERROR とし、`request_id` を含める

### iOS / Android
- API送信時に `request_id` を紐付けてログ出力
- 端末特有の情報（OS version / app version）は別枠で記録
