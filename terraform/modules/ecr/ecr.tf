# ECR Repository for Django App
resource "aws_ecr_repository" "repo_django" {
  name                 = "${var.project_name}-django"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

# ECR Repository for Postgres
resource "aws_ecr_repository" "repo_postgres" {
  name                 = "${var.project_name}-postgres"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}
