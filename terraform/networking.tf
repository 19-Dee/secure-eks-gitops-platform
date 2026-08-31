resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gw"
  }
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route"
  }
}

resource "aws_route_table_association" "pubsub-a-rta" {
  subnet_id      = aws_subnet.pubsub_a.id
  route_table_id = aws_route_table.public-route.id
}

resource "aws_route_table_association" "pubsub-b-rta" {
  subnet_id      = aws_subnet.pubsub_b.id
  route_table_id = aws_route_table.public-route.id
}
