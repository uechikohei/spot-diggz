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
  sdz_stage                   = var.sdz_stage
  sdz_region                  = var.sdz_region
  sdz_storage_bucket          = var.sdz_storage_bucket
  sdz_ui_bucket               = var.sdz_ui_bucket
  sdz_ui_public_members       = var.sdz_ui_public_members
  sdz_api_image               = var.sdz_api_image
  sdz_enable_cloud_run        = var.sdz_enable_cloud_run
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
