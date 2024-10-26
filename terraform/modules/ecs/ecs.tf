module "sg" {
  source = "../sg"
  project_name = var.project_name
  region = var.region
}

module "vpc" {
  source = "../vpc"
  project_name = var.project_name
  region = var.region
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs" {
  name = "${var.project_name}-cluster"
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.sg.alb_sg_id]
  subnets            = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  enable_deletion_protection = false
}

# Target Group for ECS (Forward traffic to port 8000)
resource "aws_lb_target_group" "tg" {
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener for the ALB on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "ecs_namespace" {
  name        = "${var.project_name}.local"
  description = "Service discovery namespace for ECS"
  vpc         = module.vpc.vpc_id
}

# Cloud Map Service for PostgreSQL
resource "aws_service_discovery_service" "postgres_service" {
  name         = "postgres"
  namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id
    dns_records {
      type = "A"
      ttl  = 10
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "td" {
  family                   = "${var.project_name}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "512"
  memory                  = "1024"
  execution_role_arn      = "arn:aws:iam::537124959582:role/ecsTaskExecutionRole"
  task_role_arn           = "arn:aws:iam::537124959582:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "postgres"
      image     = "postgres:16"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.db_port
        }
      ]
      environment = [
        {
          name  = "POSTGRES_USER"
          value = "MJqVvAyWWVYAqSEdevWlSiwLbLIAjkKA"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = "3ZoSNXGdkg5NQZf4VNKh2Qj43iPOlUqfj2tJfHTbId4rM3YkU2ejU2Ata60bNF0U"
        },
        {
          name  = "POSTGRES_DB"
          value = "ecc_project"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -U MJqVvAyWWVYAqSEdevWlSiwLbLIAjkKA -d ecc_project"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-db"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "postgres"
        }
      }
    },
    {
      name      = "django"
      image     = "537124959582.dkr.ecr.${var.region}.amazonaws.com/${var.project_name}-django:latest"
      cpu       = 256
      memory    = 512
      essential = true
      dependsOn = [
        {
          containerName = "postgres"
          condition     = "HEALTHY"
        }
      ]
      portMappings = [
        {
          containerPort = var.app_port
        }
      ]
      command = [
        "sh",
        "-c",
        "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"
      ]
      environment = [
        {
          name  = "POSTGRES_USER"
          value = var.postgres_user
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = var.postgres_password
        },
        {
          name  = "POSTGRES_DB"
          value = var.postgres_db
        },
        {
          name  = "POSTGRES_HOST"
          value = var.postgres_host
        },
        {
          name  = "POSTGRES_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "USE_DOCKER"
          value = "yes"
        },
        {
          name  = "IPYTHONDIR"
          value = "/app/.ipython"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-django"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "django"
        }
      }
    }
  ])
}

# ECS Service using Fargate
resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.ecs.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.td.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "django"
    container_port   = var.app_port
  }

  network_configuration {
    subnets          = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_1_id]
    security_groups  = [module.sg.app_sg_id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.postgres_service.arn
  }

  depends_on = [aws_lb_listener.http]
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach ECS Task Execution Policy to Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
