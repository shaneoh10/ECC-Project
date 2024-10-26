variable "app_port" {
  description = "Port the application runs on"
  type        = number
  default     = 8000
}

variable "db_port" {
  description = "Port for the database"
  type        = number
  default     = 5432
}
