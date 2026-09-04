# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Creating subnets

resource "aws_subnet" "pubsub_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name                     = "Public Subnet A"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "pubsub_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name                     = "Public Subnet B"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "privsub_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name                              = "Private Subnet A"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "privsub_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name                              = "Private Subnet B"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
