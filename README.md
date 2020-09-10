# SkateSpotSearch
スケボー初心者の方へ！練習場所をお探しですか？  
このアプリでは、
  1. 練習できる場所を登録してみんなでシェア！
  2. 登録済みのスポットへ現在地からルートを取得！  
どにいてもスケボーができる場所を探すことができます！

開発環境
- macbook pro retina mid2015
- macOS Catalina (ver10.15.6)
- docker,docker-compose

URL
---
https://sss.red-miso.work/

#### スケートスポットの登録
![新規投稿](https://media.giphy.com/media/IflyP6yeKsaD55Qazk/giphy.gif)

#### コメント投稿と削除
![コメントテスト](https://media.giphy.com/media/JoCNcrn5CrK1jUifyW/giphy.gif)


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
- いいね、コメント、フォロー機能(ajax/jquery)
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
- docker-compose環境では、webpackerコンテナを立てHMRを活用した。

- フロントはwebpackerを採用。また、bootstrap臭くならないよう使用はreboot-cssのみ、scss/css/js/jqueryで一から構築。

- googlemap apiという外部APIを主な機能として活用。

- Rspecのsystemspecにはmacへのインストールを避ける為、docker-composeにてchromedriverを含むコンテナを立てた。

- nginxとpumaの連携には、sockets通信を採用。

- codebuild,codepipeline,codedeployを用いたCICD環境を構築。


インフラ構成
---
![インフラ構成図](https://github.com/uechikohei/SkateSpotSearch/blob/images/skatespot.png)


改善すべき点
---
#### 機能が少ない。
- 都道府県別や現在地から近い登録スポットを表示する機能
- 登録スポットストック機能


作成の背景
---

　私は現在スケートボード業界で勤務して8年目になります。

2017年スケートボード業界に衝撃が走りました。それは、待望だったオリンピック競技として正式に決定したことです。  
それにより様々なメディアやSNSにより、スケートボードの露出が多くなってきました。  
そして2020年現在スケボーブームが再来していると言われています！  
実際、スケボーの販売台数はとても増加しています。  

　しかし、最近スケボーの死亡事故やマナーの悪さなどネガティブな報道が多く見受けられます。  
考えられる原因は様々あるでしょうが、  
**初心者やスケボーパークの存在を知らない方、人通りの多い場所で無茶な滑走をする方**が多いのではないかと考えました。  

そんな中アプリ開発の勉強を通して、  
**全国のスケートパーク情報から認められている公園などを皆で共有できるアプリ**
を開発することで新たに始めるスケボー人口の方達を、  
適切な練習場所へと誘導できれば業界の改善の一歩となるのではと考え開発しました。  

スケボーを愛するみんなのマナーや意識を向上させる場を提供したいと考えています。  


　私は、サーバーサイドエンジニアを目指しています。よって、  
codebuild,deploy,pipelineを用いたECS(EC2)への自動デプロイ環境を構築し、インフラ設計に力を入れた構成にしました。

