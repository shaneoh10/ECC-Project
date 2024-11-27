terraform {
  backend "gcs" {
    bucket = "ecc-project-tf-state-backend"
    prefix = "tf-infra/terraform.tfstate"
  }

  required_version = ">= 1.9.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "cloudrun" {
  source = "./modules/cloudrun"

  project_id        = var.project_id
  region            = var.region
  postgres_db       = var.postgres_db
  postgres_host     = var.postgres_host
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
}

module "artifact" {
  source = "./modules/artifact"

  project_id = var.project_id
  region     = var.region
}

module "vpc" {
  source = "./modules/vpc"

  project_id = var.project_id
  region     = var.region
}
