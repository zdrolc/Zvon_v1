output "artifact_registry_url" {
  description = "URL del Artifact Registry"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.flows.repository_id}"
}

output "docker_image" {
  description = "URL completa de la imagen Docker"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.flows.repository_id}/fintop:latest"
}

output "cloud_run_job_name" {
  description = "Nombre del Cloud Run Job"
  value       = google_cloud_run_v2_job.bank_etl.name
}

output "scheduler_job_name" {
  description = "Nombre del Cloud Scheduler Job"
  value       = google_cloud_scheduler_job.bank_etl_daily.name
}

output "service_account_email" {
  description = "Email del Service Account"
  value       = google_service_account.etl.email
}

# GitHub Actions secrets
output "github_actions_wif_provider" {
  description = "WIF_PROVIDER secret para GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github_actions.name
}

output "github_actions_service_account" {
  description = "WIF_SERVICE_ACCOUNT secret para GitHub Actions"
  value       = google_service_account.github_actions.email
}
