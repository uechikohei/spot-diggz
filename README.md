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
├── src/
│   ├── api/               # 🦀 Rust APIサーバー
│   └── ui/                # ⚛️ React UIアプリ  
├── resources/             # 🏗️ Terraform Infrastructure
├── docs/                  # 📚 ドキュメント
└── scripts/               # 🔧 開発用スクリプト
```

## 🔧 Development Commands

```bash
# 開発環境起動
./scripts/dev-start.sh

# API開発
cd src/api && cargo run      # localhost:8080

# UI開発  
cd src/ui && npm start       # localhost:3000
```

## ⚙️ 環境変数（API）

- `SDZ_AUTH_PROJECT_ID` … Firebase/Identity PlatformのプロジェクトID（例: sdz-dev）
- `SDZ_USE_FIRESTORE` … `1` でFirestore利用、未設定ならインメモリ
- `SDZ_FIRESTORE_PROJECT_ID` … FirestoreのプロジェクトID（省略時はSDZ_AUTH_PROJECT_IDを使用）
- `SDZ_FIRESTORE_TOKEN` … Firestore RESTに使うBearerトークン（`gcloud auth print-access-token` など）
- `SDZ_CORS_ALLOWED_ORIGINS` … カンマ区切りの許可オリジン（未設定時はlocalhost:3000のみ）

## 📚 Documentation

- [開発環境セットアップ](docs/DEVELOPMENT_SETUP.md)
- [プロジェクト詳細](CLAUDE.md)

## 🔌 APIエンドポイント（現在の実装状況）
- `GET /sdz/health` … ヘルスチェック
- `GET /sdz/users/me` … 認証必須。Firebase IDトークンを検証し、Firestoreの`users/{uid}`またはメモリから返却
- `POST /sdz/spots` … 認証必須。UUIDの`spotId`を払い出し、Firestoreの`spots/{uuid}`またはメモリに保存
- `GET /sdz/spots/{id}` … 公開。Firestore/メモリから取得（存在しなければ404）
- `GET /sdz/spots` … 公開。Firestore/メモリから一覧を取得


操作画面GIF
---
![新規投稿](https://media.giphy.com/media/Qlpgdcb58od3Uxij5m/giphy.gif)

![コメント機能](https://media.giphy.com/media/WANPBs7hskMVqaN6ra/giphy.gif)


使用技術
---
- Ruby:2.6.5 , Rails:6.0.2
- webpacker(bootstrap4-reboot.css/fontawesome/scss/css/js/jQuery)
- nginx,puma(sockets通信)
- Rspec(systemspec)


機能一覧
---
- ログイン機能(devise)
- 画像投稿(aws-fog/carrierwave/image_processing)
- 投稿、編集、削除、新規作成(scaffold)
- 無限スクロール(kaminari/jquery)
- いいね、コメント、フォロー機能(ajax処理)
- 検索機能(ransack)
- テストデータ投入(faker)
- 緯度経度取得(geocoder)
- 緯度経度取得時js⇔rails間で変数を受け渡す(gon)
- 2点間のルート情報取得(Directions API)
- 住所から緯度経度変換(Geocoding API)
- 緯度経度から住所変換(Reverse Geocoding API)
- 現在地取得(Geolocation API)
- Googlemap表示(Google Maps JavaScript API)
- テスト(Rspec/capybara/capybara_screenshot)
- ruby構文規約チェックツール(rubocop)
- rails構文規約チェックツール(rubocop-rails)


工夫点
---
- docker-composeを活用し、必要なリソースは直接インストールせずにコンテナを立てて作業した。
webpackerコンテナ(HMR設定の為)
chromedriverコンテナ(systemspecブラウザを使用したテストの為)

- フロントは、bootstrap臭くならないよう使用はreboot-cssのみを使用。その他はscss/css/js/jqueryで一から構築。

- google maps apiをポートフォリオのメイン機能として採用。ルート検索や現在地の取得などを

- gitへのpushからcodepipeline,codebuild,codedeployを用いたデプロイまで一貫したCICD環境を構築。


インフラ構成
---
![インフラ構成図](https://github.com/uechikohei/SkateSpotSearch/blob/images/SkateSpotSearch_drawio.png)


改善、気になっている点
---

#### アプリの機能が少ない。
- 都道府県別や現在地から近い登録スポットを表示する機能
(実装予定)

## 開発メモ: Gitで無視しているもの
- `/src/api/target/` … Rustビルド成果物。`cargo clean`で再生成可能。
- `/src/ui/node_modules/` `/src/ui/.next/` `/src/ui/build/` … フロントの依存やビルド成果物。`npm install`/`npm run build`で再生成可能。
- `/.DS_Store` … macOSのメタファイル。コードと無関係のため除外。

## 開発環境の手順まとめ

### フロントエンド
- パス: `/Users/kohei/workspace/uechikohei/spot-diggz/src/ui`
- 環境設定ファイル: `/Users/kohei/workspace/uechikohei/spot-diggz/src/ui/.env`（`.env.example`をコピー）
- 起動: `npm install && npm run dev`

### バックエンド
- パス: `/Users/kohei/workspace/uechikohei/spot-diggz/src/api`
- 初回のGoogle Cloud認証（パスワードを求められたとき）: `gcloud auth login`
- 環境設定ファイル: `/Users/kohei/workspace/uechikohei/spot-diggz/src/api/.env`（`.env.example`をコピー）
- 起動: `cargo run`

#### その他
- Rspecテストが少ない。request specが書けていない。
- git commit メッセージが重複していたり、簡潔でない内容になっている。
- リファクタリングが不十分、コードに無駄がある。

#### 不具合がみられる。
- google chromeブラウザを使用すると、google maps api の現在地取得機能や画像のカメラ撮影アップロード機能などが動作しない場合がある。
(safariやfirefoxブラウザでは、正常動作を確認済。引き続き調査中9/25~)

---


作成の背景
---

　私は現在スケートボード業界で勤務して8年目になります。

2017年スケートボード業界に衝撃が走りました。それは、待望だったオリンピック競技として正式に決定したことです。  
以降、様々なメディアやSNSによるスケートボードの露出が多くなってきました。  
現在2020年スケボーブームが再来していると言われています！  
実際、スケボーの販売台数はとても増加しています。  

　しかし、最近スケボーの死亡事故やマナーの悪さなどネガティブな報道が多く見受けられます。  
考えられる原因は様々あります、  
**初心者やスケボーパークの存在を知らない方、人通りの多い場所で無茶な滑走をする方**が多いのではないかと私は考えました。  

そんな中アプリ開発の勉強を通して、  
**全国のスケートパーク情報やその他スケボーが認められている公園などをスポットとして、皆で共有できるアプリ**
を開発することで新たに始めるスケボー人口の方達を、  
適切な練習場所へと誘導できれば業界の改善の一歩となるのではと考え開発しました。  

スケボーを愛するみんなのマナーや意識を向上させる場を提供したいと考えています。    
