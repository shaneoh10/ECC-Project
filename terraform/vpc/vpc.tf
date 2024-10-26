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
