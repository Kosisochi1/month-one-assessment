terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "my-backend-terraform-state-s3-bucket"
    key    = "global/s3/terraform.tfstate"
    region = "eu-west-1"
    #dynamodb_table = "my-backend-terraform-state-lock-asset"
    use_lockfile = true
    encrypt      = true
  }
}
# provider 
provider "aws" {
  region  = var.aws_region
  profile = var.my_profile
}


#  create VPC
resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techcorp-vpc"
  }
}

# Availabity zone from  data

data "aws_availability_zones" "availabile_zone" {
  state = "available"

}

#   Public SUBNETS
resource "aws_subnet" "techcorp_public_subnet_1" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.availabile_zone.names[0]

  tags = { Name = "techcorp-public-subnet-1" }
}

resource "aws_subnet" "techcorp_public_subnet_2" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.availabile_zone.names[1]

  tags = { Name = "techcorp-public-subnet-2" }
}


# Private SUBNETS

resource "aws_subnet" "techcorp_private_subnet_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.availabile_zone.names[0]

  tags = { Name = "techcorp-private-subnet-1" }
}

resource "aws_subnet" "techcorp_private_subnet_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.availabile_zone.names[1]

  tags = { Name = "techcorp-private-subnet-2" }
}


# Internet Gateway
resource "aws_internet_gateway" "techcorp_internet_gateway" {
  vpc_id = aws_vpc.techcorp_vpc.id
  tags   = { Name = "techcorp-internet-gateway" }
}

# EIP for NATs
resource "aws_eip" "techcorp_eip_gateway_1" {
  domain     = "vpc"
  tags       = { Name = "techcorp-eip-gateway-1" }
  depends_on = [aws_internet_gateway.techcorp_internet_gateway]
}

resource "aws_eip" "techcorp_eip_gateway_2" {
  domain     = "vpc"
  tags       = { Name = "techcorp-eip-gateway-2" }
  depends_on = [aws_internet_gateway.techcorp_internet_gateway]
}

# NAT Gateways (in public subnets)
resource "aws_nat_gateway" "techcorp_nat_gateway_1" {
  allocation_id = aws_eip.techcorp_eip_gateway_1.id
  subnet_id     = aws_subnet.techcorp_public_subnet_1.id

  tags       = { Name = "techcorp-nat-gateway-1" }
  depends_on = [aws_internet_gateway.techcorp_internet_gateway]
}

resource "aws_nat_gateway" "techcorp_nat_gateway_2" {
  allocation_id = aws_eip.techcorp_eip_gateway_2.id
  subnet_id     = aws_subnet.techcorp_public_subnet_2.id

  tags = { Name = "techcorp-nat-gateway-2" }

  depends_on = [aws_internet_gateway.techcorp_internet_gateway]
}



# Route tables for Gateways
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techcorp_internet_gateway.id
  }

  tags = { Name = "techcorp-route-table-public-subnet" }
}


# Route table for private NAT

resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.techcorp_nat_gateway_1.id
  }

  tags = { Name = "techcorp-route-table-private-subnet-1" }
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.techcorp_nat_gateway_2.id
  }

  tags = { Name = "techcorp-route-table-private-subnet-2" }
}

# Association route table with public subnets
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.techcorp_public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.techcorp_public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
# Associate route table with private subnets
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.techcorp_private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.techcorp_private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}

# SECURITY GROUPS 
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "Allow SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from internet; full egress"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ALB_SG" }
}

resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.techcorp_vpc.id

  # allow ALB -> web servers on port 80
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # optional: allow HTTPS from anywhere (if you later add 443 listener)
  ingress {
    description     = "Allow HTTPS from anywhere"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow SSH from bastion
  ingress {
    description     = "Allow SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-server-sg" }
}

resource "aws_security_group" "db_server_sg" {
  name        = "db-server-sg"
  description = "Security group for DB server"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "Allow Postgres from web servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }
  ingress {
    description     = "Allow Postgres from Bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }


  ingress {
    description     = "Allow SSH from Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "DB-server" }
}

# Key pair
resource "aws_key_pair" "techcorp_key" {
  key_name   = var.key_pair_name
  public_key = file("~/.ssh/id_rsa.pub")
}

# AMI data
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Instances 
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.db_server_instance_type
  subnet_id              = aws_subnet.techcorp_private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.db_server_sg.id]
  key_name               = aws_key_pair.techcorp_key.key_name
  user_data              = file("${path.module}/user_data/db_server_setup.sh")


  depends_on = [aws_nat_gateway.techcorp_nat_gateway_1]

  tags = {
    Name = "db_server"
  }
}

resource "aws_instance" "web_server" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_server_instance_type
  subnet_id = element([
    aws_subnet.techcorp_private_subnet_1.id,
    aws_subnet.techcorp_private_subnet_2.id
  ], count.index)

  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  key_name               = aws_key_pair.techcorp_key.key_name
  user_data              = file("${path.module}/user_data/web_server_setup.sh")



  tags = {
    Name = "web_server"
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastio_server_instance_type
  subnet_id              = aws_subnet.techcorp_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.techcorp_key.key_name

  tags = {
    Name = "bastion_server"
  }


  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum amazon-linux-extras install postgresql14 -y
              yum install postgresql -y

              EOF
}

# ALB + target group + listener
resource "aws_lb" "alb" {
  name               = "techcorp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.techcorp_public_subnet_1.id, aws_subnet.techcorp_public_subnet_2.id]

  enable_deletion_protection = false

  tags = { Environment = "Dev"
  Name = "ALB" }
}

resource "aws_lb_target_group" "al_tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id

  health_check {
    path     = "/"
    port     = "80"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.al_tg.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.al_tg.arn
  }
}
