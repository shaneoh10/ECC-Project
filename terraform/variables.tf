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

variable postgres_password {
  description = "Postgres password"
  type        = string
  sensitive   = true
}

variable postgres_host {
  description = "Postgres host"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of the project to be used in resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}
