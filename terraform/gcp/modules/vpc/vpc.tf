# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "sn1" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1a"
  }
}

resource "aws_subnet" "sn2" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1b"
  }
}

# Private Subnets
resource "aws_subnet" "private_sn1" {
  cidr_block              = "10.0.3.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-1a"
  }
}

resource "aws_subnet" "private_sn2" {
  cidr_block              = "10.0.4.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-1b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public_route1" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.sn1.id
}

resource "aws_route_table_association" "public_route2" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.sn2.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private_route1" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_sn1.id
}

resource "aws_route_table_association" "private_route2" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_sn2.id
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

# App Security Group (ECS Tasks in private subnet)
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.vpc.id

  # Allow traffic from ALB
  ingress {
    description     = "Allow ALB traffic to Django"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow outbound internet access (via NAT Gateway)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_sg"
  }
}

# PostgreSQL Security Group (in private subnet)
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security group for PostgreSQL"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Allow traffic from ECS app tasks to PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_sg"
  }
}
