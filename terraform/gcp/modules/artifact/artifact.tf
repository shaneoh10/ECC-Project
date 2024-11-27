# GCP Artifact Registry for Django App
resource "google_artifact_registry_repository" "repo_django" {
  repository_id = "${var.project_id}-django"
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id

  labels = {
    image_tag_mutability = "MUTABLE"
  }
}

# GCP Artifact Registry for Postgres
resource "google_artifact_registry_repository" "repo_postgres" {
  repository_id = "${var.project_id}-postgres"
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id

  labels = {
    image_tag_mutability = "MUTABLE"
  }
}
