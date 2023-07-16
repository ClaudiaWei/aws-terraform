resource "aws_vpc" "project_vpc" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = "true"
  enable_dns_support               = "true"
  instance_tenancy                 = "default"
  tags = {
    Terraform   = "true"
    Name        = "project_vpc"
  }
}

resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_igw"
  }
}

resource "aws_eip" "project_ngw_eip" {
  vpc                  = "true"
  network_border_group = var.region
  public_ipv4_pool     = "amazon"
  tags = {
    Terraform   = "true"
    Name        = "project_ngw_eip"
  }
}

resource "aws_subnet" "project_public_subnet_1a" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Terraform   = "true"
    Name        = "project_public_subnet_1a"
  }
}

resource "aws_subnet" "project_public_subnet_1c" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}c"
  tags = {
    Terraform   = "true"
    Name        = "project_public_subnet_1c"
  }
}

resource "aws_subnet" "project_private_subnet_1a" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Terraform   = "true"
    Name        = "project_private_subnet_1a"
  }
}

resource "aws_subnet" "project_private_subnet_1c" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}c"
  tags = {
    Terraform   = "true"
    Name        = "project_private_subnet_1c"
  }
}

resource "aws_nat_gateway" "project_ngw" {
  allocation_id     = aws_eip.project_ngw_eip.id
  connectivity_type = "public"
  subnet_id         = aws_subnet.project_public_subnet_1a.id
  tags = {
    Terraform   = "true"
    Name        = "project_ngw"
  }
}

resource "aws_route_table" "project_main_route_table" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_main_route_table"
  }
}

resource "aws_route_table" "project_public_route_table" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_public_route_table"
  }
}

resource "aws_route_table" "project_private_route_table" {
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project_ngw.id
  }
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_private_route_table"
  }
}

resource "aws_route_table_association" "project_route_table_association_public_1a" {
  subnet_id      = aws_subnet.project_public_subnet_1a.id
  route_table_id = aws_route_table.project_public_route_table.id 
}

resource "aws_route_table_association" "project_route_table_association_public_1c" {
  subnet_id      = aws_subnet.project_public_subnet_1c.id
  route_table_id = aws_route_table.project_public_route_table.id 
}

resource "aws_route_table_association" "project_route_table_association_private_1a" {
  subnet_id      = aws_subnet.project_private_subnet_1a.id
  route_table_id = aws_route_table.project_private_route_table.id
}

resource "aws_route_table_association" "project_route_table_association_private_1c" {
  subnet_id      = aws_subnet.project_private_subnet_1c.id
  route_table_id = aws_route_table.project_private_route_table.id
}

resource "aws_security_group" "project_website" {
  name          = "project_website"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    description     = "Allow ALB to access high port"
    from_port       = "0"
    protocol        = "tcp"
    security_groups = [aws_security_group.project_alb.id]
    self            = "false"
    to_port         = "65535"
  }

  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_website"
  }
}

resource "aws_security_group" "project_alb" {
  name          = "project_alb"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    cidr_blocks = [""]
    from_port   = "443"
    protocol    = "tcp"
    self        = "false"
    to_port     = "443"
  }
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_alb"
  }
}

resource "aws_security_group" "project_lambda" {
  name          = "project_lambda"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_lambda"
  }
}

resource "aws_security_group" "project_rds" {
  name          = "project_rds"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    description     = "for lambda/website"
    from_port       = "5432"
    protocol        = "tcp"
    security_groups = [aws_security_group.project_lambda.id, aws_security_group.project_website.id]
    self            = "false"
    to_port         = "5432"
  }
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Terraform   = "true"
    Name        = "project_rds"
  }
}

