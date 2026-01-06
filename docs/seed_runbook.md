# dev seed運用ルール

## 概要

dev 環境のテストデータ（スポット＋画像）を手動で投入する手順。
CI/CD や Cloud Build からは実行しない（自動流入を防止するため）。

## 前提

- GCP 認証が完了していること
- `web/sdz_seed_spots.sh` を実行する
- `web/sample/` 配下の画像を使用する
- Firestore の `spots` コレクションは全削除される

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
```

4) seed 実行
```bash
chmod +x ./web/sdz_seed_spots.sh
./web/sdz_seed_spots.sh
```

5) 反映確認
```bash
gcloud firestore documents list spots --project sdz-dev
gsutil ls gs://sdz-dev-img-bucket/spots
```

## 注意点

- `web/sdz_seed_spots.sh` は Firestore の `spots` を全削除してから再投入する。
- API URL はスクリプト内で固定しているため、変更があれば更新する。
- CI/CD や Cloud Build から `web/sdz_seed_spots.sh` は呼び出していないことを維持する。
