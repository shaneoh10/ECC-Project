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
