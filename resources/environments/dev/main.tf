resource "google_project_service" "sdz_services" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "firestore.googleapis.com",
    "iam.googleapis.com",
    "identitytoolkit.googleapis.com",
    "storage.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_firebase_project" "sdz_firebase" {
  provider = google-beta
  project  = var.sdz_project_id

  depends_on = [google_project_service.sdz_services]
}

resource "google_firestore_database" "sdz_firestore" {
  provider    = google-beta
  project     = var.sdz_project_id
  name        = "(default)"
  location_id = var.sdz_firestore_location
  type        = "NATIVE"

  depends_on = [google_firebase_project.sdz_firebase]
}

resource "google_storage_bucket" "sdz_spot_media" {
  name     = var.sdz_storage_bucket
  location = var.sdz_region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  depends_on = [google_project_service.sdz_services]
}

resource "google_service_account" "sdz_dev_api_sa" {
  account_id   = "sdz-dev-api-sa"
  display_name = "spot-diggz API用サービスアカウント"
  project      = var.sdz_project_id
}

resource "google_service_account" "sdz_dev_deploy_sa" {
  account_id   = "sdz-dev-deploy-sa"
  display_name = "spot-diggz デプロイ用サービスアカウント"
  project      = var.sdz_project_id
}

resource "google_service_account" "sdz_dev_terraform_sa" {
  account_id   = "sdz-dev-terraform-sa"
  display_name = "spot-diggz terraform用サービスアカウント"
  project      = var.sdz_project_id
}

resource "google_service_account" "sdz_firebase_adminsdk_sa" {
  account_id   = "firebase-adminsdk-fbsvc"
  display_name = "Firebase Admin SDK Service Agent"
  project      = var.sdz_project_id
}

resource "google_firebase_web_app" "sdz_web_app" {
  provider     = google-beta
  project      = var.sdz_project_id
  display_name = var.sdz_web_app_display_name

  depends_on = [google_firebase_project.sdz_firebase]
}

resource "google_firebase_android_app" "sdz_android_app" {
  provider     = google-beta
  project      = var.sdz_project_id
  display_name = var.sdz_android_app_display_name
  package_name = var.sdz_android_package_name

  count      = var.sdz_android_package_name == "" ? 0 : 1
  depends_on = [google_firebase_project.sdz_firebase]
}

resource "google_firebase_apple_app" "sdz_ios_app" {
  provider     = google-beta
  project      = var.sdz_project_id
  display_name = var.sdz_ios_app_display_name
  bundle_id    = var.sdz_ios_bundle_id

  count      = var.sdz_ios_bundle_id == "" ? 0 : 1
  depends_on = [google_firebase_project.sdz_firebase]
}
