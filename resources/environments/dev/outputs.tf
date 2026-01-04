output "sdz_storage_bucket" {
  value       = google_storage_bucket.sdz_spot_media.name
  description = "Spot media bucket name"
}

output "sdz_ui_bucket" {
  value       = google_storage_bucket.sdz_ui_bucket.name
  description = "UI hosting bucket name"
}

output "sdz_artifact_repo" {
  value       = google_artifact_registry_repository.sdz_api_repo.name
  description = "Artifact Registry repository name"
}

output "sdz_cloud_run_service" {
  value       = var.sdz_enable_cloud_run ? google_cloud_run_service.sdz_api[0].name : ""
  description = "Cloud Run service name"
}

output "sdz_firestore_database" {
  value       = google_firestore_database.sdz_firestore.name
  description = "Firestore database name"
}

output "sdz_firebase_web_app_id" {
  value       = google_firebase_web_app.sdz_web_app.app_id
  description = "Firebase Web App ID"
}
