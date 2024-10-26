terraform {
    required_version = ">= 1.9.7"
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
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
    project_name = var.project_name
    region = var.region
    postgres_db = var.postgres_db
    postgres_host = var.postgres_host
    postgres_user = var.postgres_user
    postgres_password = var.postgres_password
}

module "ecr" {
    source = "./modules/ecr"
    project_name = var.project_name
    region = var.region
}

module "vpc" {
    source = "./modules/vpc"
    project_name = var.project_name
    region = var.region
}
