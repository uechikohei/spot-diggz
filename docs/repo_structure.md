# リポジトリ構成方針（将来案）

spot-diggz を将来的にモノレポ管理する場合の構成案を整理する。
現時点の優先度は低く、移行は別課題で検討する。

## 現状
- `api/` : Rust API
- `ui/` : React UI
- `resources/` : Terraform / インフラ

## 将来案（モノレポ化）
```
spot-diggz/
  web/
    api/
    ui/
    resources/
  ios/
  android/
```

## 補足
- 既存構成を即時変更する予定はない
- iOS / Android が本格着手になったタイミングで再検討する
