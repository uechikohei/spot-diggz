output "sdz_storage_bucket" {
  value       = google_storage_bucket.sdz_spot_media.name
  description = "Spot media bucket name"
}

output "sdz_firestore_database" {
  value       = google_firestore_database.sdz_firestore.name
  description = "Firestore database name"
}

output "sdz_firebase_web_app_id" {
  value       = google_firebase_web_app.sdz_web_app.app_id
  description = "Firebase Web App ID"
}
