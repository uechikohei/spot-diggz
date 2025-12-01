# Firestoreのusersドキュメントが作成されない場合の対処

## 症状
- Firebase Auth にはユーザーが作成されるが、Firestore の `users/{uid}` が生成されない。
- UI 上では「Authエラー: Missing or insufficient permissions.」などが出る場合がある。

## 原因
- クライアント側で「同一メールの重複チェック」として `users` コレクションをメールアドレスでクエリしていたが、Firestore ルールでクエリが許可されず `permission-denied` となり、`setDoc` が実行されなかった。
- ルールは `request.auth.uid == userId` で `users/{uid}` への本人書き込みのみ許可しており、コレクション全体をメールで検索する権限がなかった。

## 解決策
- クエリによる重複チェックを削除し、`users/{uid}` へ直接 `setDoc` するのみのシンプルな処理に変更。
- Firestore ルール（開発用例）は以下の通り：
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```
- 上記を Firebase CLI でデプロイ（`firebase deploy --only firestore:rules --project sdz-dev`）。

## 再発防止のヒント
- ルールで許可されないクエリ（コレクション全件スキャン等）をアプリに組み込まない。
- 書き込み失敗時のログ（`console.error` や Network タブ）を必ず確認する。
- 「UIDでの直接アクセスなら許可、集合クエリは原則禁止」という運用に統一するとトラブルが減る。
