provider "google" {
  project = var.sdz_project_id
  region  = var.sdz_region
}

provider "google-beta" {
  project = var.sdz_project_id
  region  = var.sdz_region
}

module "sdz_dev" {
  source = "./environments/dev"

  sdz_project_id              = var.sdz_project_id
  sdz_region                  = var.sdz_region
  sdz_storage_bucket          = var.sdz_storage_bucket
  sdz_firestore_location      = var.sdz_firestore_location
  sdz_web_app_display_name    = var.sdz_web_app_display_name
  sdz_android_package_name    = var.sdz_android_package_name
  sdz_android_app_display_name = var.sdz_android_app_display_name
  sdz_ios_bundle_id           = var.sdz_ios_bundle_id
  sdz_ios_app_display_name    = var.sdz_ios_app_display_name

  providers = {
    google      = google
    google-beta = google-beta
  }
}
