variable "postgres_db" {
  description = "Postgres database"
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "Postgres user"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}

variable "postgres_host" {
  description = "Postgres host"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "ID of the project to be used"
  type        = string
  default     = "ecc-project-443018"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "bucket_name" {
  description = "Remote S3 Bucket Name"
  type        = string
  default     = "ecc-project-tf-state-backend"
}
