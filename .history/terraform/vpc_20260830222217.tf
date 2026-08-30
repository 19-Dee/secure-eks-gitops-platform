# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}


# Creating subnets

resource "aws_subnet" "pubsub_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subenet A"
  }
}

resource "aws_subnet" "pubsub_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Public Subenet B"
  }
}

resource "aws_subnet" "pubsub_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Public Subenet C"
  }
}

resource "aws_subnet" "privsub_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"

  tags = {
    Name = "Private Subenet A"
  }
}

resource "aws_subnet" "privsub_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.12.0/24"

  tags = {
    Name = "Private Subenet B"
  }
}
