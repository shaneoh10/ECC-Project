terraform {
    required_version = ">= 0.13"
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "eu-west-1"
}

module "tf-state" {
  source      = "./modules/tf-state"
  bucket_name = "ecc-project-tf-state-backend"
}

module "ecs" {
  source = "./modules/ecs"

  postgres_db = var.postgres_db
  postgres_host = var.postgres_host
  postgres_user = var.postgres_user
  postgres_password = var.postgres_password
}
