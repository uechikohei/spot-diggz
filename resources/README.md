# spot-diggz Terraform（dev）

## 概要
`resources/` は dev 環境向けの IaC を管理する。既存の GCP リソースがある場合は **先に import** してから apply を行う。

## 初期セットアップ
```bash
cd resources
terraform init
```

## 変数ファイル
```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

## 既存サービスアカウントの import
```bash
terraform import \
  module.sdz_dev.google_service_account.sdz_dev_api_sa \
  projects/sdz-dev/serviceAccounts/sdz-dev-api-sa@sdz-dev.iam.gserviceaccount.com

terraform import \
  module.sdz_dev.google_service_account.sdz_dev_deploy_sa \
  projects/sdz-dev/serviceAccounts/sdz-dev-deploy-sa@sdz-dev.iam.gserviceaccount.com

terraform import \
  module.sdz_dev.google_service_account.sdz_dev_terraform_sa \
  projects/sdz-dev/serviceAccounts/sdz-dev-terraform-sa@sdz-dev.iam.gserviceaccount.com

terraform import \
  module.sdz_dev.google_service_account.sdz_firebase_adminsdk_sa \
  projects/sdz-dev/serviceAccounts/firebase-adminsdk-fbsvc@sdz-dev.iam.gserviceaccount.com
```

## Plan / Apply
```bash
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 補足
- `sdz-{env}-img-bucket` を Storage バケット命名の標準とする。
- Firebase Web App は常に作成し、iOS/Android は bundle/package が設定された場合のみ作成する。
