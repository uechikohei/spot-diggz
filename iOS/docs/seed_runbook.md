# dev seed運用ルール

## 概要

dev 環境のテストデータ（スポット＋画像）を手動で投入する手順。
CI/CD や Cloud Build からは実行しない（自動流入を防止するため）。

## 前提

- GCP 認証が完了していること
- `web/sdz_seed_spots.sh` を実行する
- `web/sample/` 配下の画像を使用する
- Firestore の `spots` コレクションは全削除される
- `SDZ_API_URL` を実行環境に合わせて指定する

## 手順

1) GCP 認証とプロジェクト設定
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project sdz-dev
```

2) 画像を削除（必要な場合のみ）
```bash
gsutil -m rm "gs://sdz-dev-img-bucket/spots/**"
```

3) 環境変数を設定
```bash
export YOUR_FIREBASE_WEB_API_KEY="YOUR_FIREBASE_WEB_API_KEY"
export TEST_USER_ID="YOUR_TEST_EMAIL"
export TEST_USER_PASSWORD="YOUR_TEST_PASSWORD"
set -a
source web/ui/.env.local
set +a
export SDZ_API_URL="${VITE_SDZ_API_URL}"
```

4) seed 実行（引数指定の例）
```bash
YOUR_FIREBASE_WEB_API_KEY="YOUR_FIREBASE_WEB_API_KEY" \
TEST_USER_ID="YOUR_TEST_EMAIL" \
TEST_USER_PASSWORD="YOUR_TEST_PASSWORD" \
SDZ_API_URL="${VITE_SDZ_API_URL}" \
./web/sdz_seed_spots.sh
```

5) 反映確認
```bash
gcloud firestore documents list spots --project sdz-dev
gsutil ls gs://sdz-dev-img-bucket/spots
```

## 注意点

- `web/sdz_seed_spots.sh` は Firestore の `spots` を全削除してから再投入する。
- API URL は `SDZ_API_URL` で指定する。
- CI/CD や Cloud Build から `web/sdz_seed_spots.sh` は呼び出していないことを維持する。
