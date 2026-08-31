resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gw"
  }
}

resource "aws_route_table" "gw-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "gw-rt"
  }
}

resource "aws_route_table" "pubsub-a-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "pubsub-a-rt"
  }
}

resource "aws_route_table" "pubsub-b-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.2.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "pubsub-b-rt"
  }
}


resource "aws_route_table_association" "gw-rta" {
  gateway_id     = aws_internet_gateway.gw.id
  route_table_id = aws_route_table.gw-rt.id
}

resource "aws_route_table_association" "pubsub-a-rta" {
  subnet_id      = aws_subnet.pubsub_a.id
  route_table_id = aws_route_table.pubsub-a-rt.id
}

resource "aws_route_table_association" "pubsub-b-rta" {
  subnet_id      = aws_subnet.pubsub_b.id
  route_table_id = aws_route_table.pubsub-b-rt.id
}
