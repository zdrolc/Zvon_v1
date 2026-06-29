terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Obtener información del proyecto
data "google_project" "project" {}

# =============================================================================
# GitHub Actions - Workload Identity Federation
# =============================================================================

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions"
  description  = "Service account for GitHub Actions CI/CD"
}

# Permisos para GitHub Actions
resource "google_project_iam_member" "github_actions_artifact_registry" {
  project = var.gcp_project
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_cloud_run" {
  project = var.gcp_project
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Permitir que GitHub repo use el Service Account
resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# Permitir que GitHub Actions use el service account del ETL (para actualizar Cloud Run Job)
resource "google_service_account_iam_member" "github_actions_act_as_etl" {
  service_account_id = google_service_account.etl.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

# Artifact Registry para imágenes Docker
resource "google_artifact_registry_repository" "flows" {
  repository_id = "etl-flows"
  description   = "Docker images for ETL flows"
  format        = "DOCKER"
  location      = var.gcp_region
}

# Service Account para Cloud Run
resource "google_service_account" "etl" {
  account_id   = "etl-cloud-run"
  display_name = "ETL Cloud Run"
  description  = "Service account for ETL Cloud Run jobs"
}

# Permiso: Invocar Cloud Run Jobs
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.gcp_project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.etl.email}"
}

# Permiso: Leer imágenes del Artifact Registry (para el ETL service account)
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.etl.email}"
}

# Permiso: Cloud Run Service Agent necesita leer imágenes del Artifact Registry
resource "google_project_iam_member" "cloud_run_agent_artifact_registry" {
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# Cloud Run Job - ETL de transacciones
resource "google_cloud_run_v2_job" "bank_etl" {
  name     = "bank-transactions-etl"
  location = var.gcp_region

  template {
    template {
      containers {
        image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.flows.repository_id}/fintop:latest"

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "SUPABASE_URL"
          value = var.supabase_url
        }
        env {
          name  = "SUPABASE_SERVICE_KEY"
          value = var.supabase_service_key
        }
        env {
          name  = "GC_SECRET_ID"
          value = var.gc_secret_id
        }
        env {
          name  = "GC_SECRET_KEY"
          value = var.gc_secret_key
        }
        env {
          name  = "TELEGRAM_BOT_TOKEN"
          value = var.telegram_bot_token
        }
        env {
          name  = "TELEGRAM_CHAT_ID"
          value = var.telegram_chat_id
        }
      }

      service_account = google_service_account.etl.email
      timeout         = "300s"
    }
  }

  depends_on = [google_artifact_registry_repository.flows]
}

# Cloud Scheduler - Ejecuta el ETL a las 6:00 AM
resource "google_cloud_scheduler_job" "bank_etl_daily" {
  name        = "bank-etl-daily"
  description = "Ejecuta ETL de transacciones bancarias diariamente a las 6 AM"
  schedule    = "0 6 * * *"
  time_zone   = "Europe/Madrid"

  http_target {
    uri         = "https://${var.gcp_region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.gcp_project}/jobs/${google_cloud_run_v2_job.bank_etl.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.etl.email
    }
  }

  depends_on = [google_cloud_run_v2_job.bank_etl]
}
