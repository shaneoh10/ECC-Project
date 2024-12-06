# GCP Artifact Registry for Django App
resource "google_artifact_registry_repository" "repo_django" {
  repository_id = "${var.project_id}-django"
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id
  labels = {
    image-tag-mutability = "mutable"
  }
}

resource "google_artifact_registry_repository_iam_binding" "repo_django_public" {
  repository = google_artifact_registry_repository.repo_django.id
  role       = "roles/artifactregistry.reader"

  members = [
    "allUsers"
  ]
}

# GCP Artifact Registry for Postgres
resource "google_artifact_registry_repository" "repo_postgres" {
  repository_id = "${var.project_id}-postgres"
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id
  labels = {
    image-tag-mutability = "mutable"
  }
}

resource "google_artifact_registry_repository_iam_binding" "repo_postgres_public" {
  repository = google_artifact_registry_repository.repo_postgres.id
  role       = "roles/artifactregistry.reader"

  members = [
    "allUsers"
  ]
}
