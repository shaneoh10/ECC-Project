variable "project_name" {
  description = "Name of the project to be used in resource naming"
  type        = string
  default     = "ecc-project"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}
