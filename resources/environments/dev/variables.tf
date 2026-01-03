variable "sdz_project_id" {
  type        = string
  description = "GCP project ID (e.g. sdz-dev)"
}

variable "sdz_region" {
  type        = string
  description = "Default region"
}

variable "sdz_storage_bucket" {
  type        = string
  description = "Cloud Storage bucket name for spot media"
}

variable "sdz_firestore_location" {
  type        = string
  description = "Firestore database location"
}

variable "sdz_web_app_display_name" {
  type        = string
  description = "Firebase Web App display name"
}

variable "sdz_android_package_name" {
  type        = string
  description = "Android package name (empty to skip)"
  default     = ""
}

variable "sdz_android_app_display_name" {
  type        = string
  description = "Firebase Android App display name"
  default     = "spot-diggz android"
}

variable "sdz_ios_bundle_id" {
  type        = string
  description = "iOS bundle ID (empty to skip)"
  default     = ""
}

variable "sdz_ios_app_display_name" {
  type        = string
  description = "Firebase iOS App display name"
  default     = "spot-diggz ios"
}
