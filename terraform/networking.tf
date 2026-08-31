resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gw"
  }
}

resource "aws_nat_gateway" "pubsub_a_ngw" {
  allocation_id = aws_eip.pubsub_a_eip.id
  subnet_id     = aws_subnet.pubsub_a.id

  tags = {
    Name = "gw NAT for public subnet a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "pubsub_a_eip" {
}

resource "aws_nat_gateway" "pubsub_b_ngw" {
  allocation_id = aws_eip.pubsub_b_eip.id
  subnet_id     = aws_subnet.pubsub_b.id

  tags = {
    Name = "gw NAT for public subnet b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "pubsub_b_eip" {
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}




resource "aws_route_table_association" "pubsub_a_rta" {
  subnet_id      = aws_subnet.pubsub_a.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "pubsub_b_rta" {
  subnet_id      = aws_subnet.pubsub_b.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_nat_gateway_eip_association" "pubsub_a_eip_association" {
  allocation_id  = aws_eip.pubsub_a_eip.id
  nat_gateway_id = aws_nat_gateway.pubsub_a_ngw.id
}

resource "aws_nat_gateway_eip_association" "pubsub_b_eip_association" {
  allocation_id  = aws_eip.pubsub_b_eip.id
  nat_gateway_id = aws_nat_gateway.pubsub_b_ngw.id
}
