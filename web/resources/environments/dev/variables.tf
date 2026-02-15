variable "sdz_project_id" {
  type        = string
  description = "GCP project ID (e.g. sdz-dev)"
}

variable "sdz_stage" {
  type        = string
  description = "Stage name (dev/stg/prod)"
}

variable "sdz_region" {
  type        = string
  description = "Default region"
}

variable "sdz_storage_bucket" {
  type        = string
  description = "Cloud Storage bucket name for spot media"
}

variable "sdz_media_public_members" {
  type        = list(string)
  description = "Members granted storage.objectViewer on media bucket (empty to skip)"
  default     = []
}

variable "sdz_ui_bucket" {
  type        = string
  description = "Cloud Storage bucket name for UI hosting"
}

variable "sdz_ui_public_members" {
  type        = list(string)
  description = "Members granted storage.objectViewer on UI bucket (empty to skip)"
  default     = []
}

variable "sdz_api_image" {
  type        = string
  description = "Container image for Cloud Run"
}

variable "sdz_cors_allowed_origins" {
  type        = string
  description = "Comma-separated allowed origins for API CORS"
  default     = ""
}

variable "sdz_auth_project_id" {
  type        = string
  description = "Firebase Auth project ID for JWT validation"
  default     = ""
}

variable "sdz_use_firestore" {
  type        = bool
  description = "Enable Firestore repositories in API"
  default     = true
}

variable "sdz_firestore_project_id" {
  type        = string
  description = "Firestore project ID (defaults to auth project if empty)"
  default     = ""
}

variable "sdz_storage_service_account_email" {
  type        = string
  description = "Service account email used for signed URL generation"
  default     = ""
}

variable "sdz_storage_signed_url_expires_secs" {
  type        = number
  description = "Signed URL expiration seconds"
  default     = 900
}

variable "sdz_cloudbuild_source_bucket" {
  type        = string
  description = "Cloud Build source bucket name for build inputs"
}

variable "sdz_enable_wif" {
  type        = bool
  description = "Enable Workload Identity Federation for GitHub Actions"
  default     = false
}

variable "sdz_wif_pool_id" {
  type        = string
  description = "Workload Identity Pool ID"
}

variable "sdz_wif_provider_id" {
  type        = string
  description = "Workload Identity Provider ID"
}

variable "sdz_github_repository" {
  type        = string
  description = "GitHub repository in owner/name format"
}

variable "sdz_github_ref" {
  type        = string
  description = "GitHub ref for WIF condition (e.g. refs/heads/develop). Empty disables ref check"
}

variable "sdz_enable_cloud_run" {
  type        = bool
  description = "Create Cloud Run service (requires image to exist)"
  default     = false
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
  default     = "SpotDiggz Android"
}

variable "sdz_ios_bundle_id" {
  type        = string
  description = "iOS bundle ID (empty to skip)"
  default     = ""
}

variable "sdz_ios_app_display_name" {
  type        = string
  description = "Firebase iOS App display name"
  default     = "SpotDiggz iOS"
}
