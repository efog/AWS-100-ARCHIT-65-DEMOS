resource "aws_vpc" "base_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = "${var.tags}"
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = "${aws_vpc.base_vpc.id}"
  availability_zone = "us-west-1c"
  cidr_block        = "10.0.0.0/28"
  tags              = "${var.tags}"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = "${aws_vpc.base_vpc.id}"
  availability_zone = "us-west-1b"
  cidr_block        = "10.0.0.16/28"
  tags              = "${var.tags}"
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = "${aws_vpc.base_vpc.id}"
  availability_zone = "us-west-1c"
  cidr_block        = "10.0.0.32/27"
  tags              = "${var.tags}"
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = "${aws_vpc.base_vpc.id}"
  availability_zone = "us-west-1b"
  cidr_block        = "10.0.0.64/27"
  tags              = "${var.tags}"
}

resource "aws_internet_gateway" "network_internet_gateway" {
  vpc_id = "${aws_vpc.base_vpc.id}"
  tags   = "${var.tags}"
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = "${aws_subnet.public_subnet_a.id}"
  tags          = "${var.tags}"
  allocation_id = "${aws_eip.nat_gateway_eip.id}"
}

resource "aws_eip" "nat_gateway_eip" {}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.base_vpc.id}"
  tags   = "${var.tags}"
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.base_vpc.id}"
  tags   = "${var.tags}"
}

resource "aws_route_table_association" "public_route_table_association_a" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id      = "${aws_subnet.public_subnet_a.id}"
}

resource "aws_route_table_association" "public_route_table_association_b" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id      = "${aws_subnet.public_subnet_b.id}"
}

resource "aws_route_table_association" "private_route_table_association_a" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  subnet_id      = "${aws_subnet.private_subnet_a.id}"
}

resource "aws_route_table_association" "private_route_table_association_b" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  subnet_id      = "${aws_subnet.private_subnet_b.id}"
}

resource "aws_route" "public_igw_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.network_internet_gateway.id}"
  route_table_id         = "${aws_route_table.public_route_table.id}"
}

resource "aws_route" "public_natgw_route" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gateway.id}"
  route_table_id         = "${aws_route_table.private_route_table.id}"
}

resource "aws_security_group" "alb_security_group" {
  vpc_id = "${aws_vpc.base_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_security_group" {
  vpc_id = "${aws_vpc.base_vpc.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb_security_group.id}"]
  }
}

resource "aws_lb" "application_load_balancer" {
  name               = "web-alb"
  tags               = "${var.tags}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_security_group.id}"]
  subnets            = ["${aws_subnet.public_subnet_a.id}", "${aws_subnet.public_subnet_b.id}"]
}
