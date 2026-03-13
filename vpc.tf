# Terraform configuration for AWS VPC, subnets, internet gateway, route tables, and security groups for deploying Flask and Express applications on ECS.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

# Create public and private subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Availability zones data source to distribute subnets across AZs
data "aws_availability_zones" "available" {}

# Create the Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# Create a Public Route Table 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate Public Subnets with the Public Route Table to enable internet access
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for the Load Balancer (ALB) to allow inbound HTTP traffic and outbound traffic to the ECS tasks and the internet
resource "aws_security_group" "lb_sg" {
  name        = "alb-security-group"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5000
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for the ECS Tasks to allow inbound traffic only from the Load Balancer on specific ports and outbound traffic to the internet
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-security-group"
  vpc_id      = aws_vpc.main.id

  # Allow traffic ONLY from the Load Balancer on the specific ports (80 for Express, 5000 for Flask)
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5000
    to_port     = 5000
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 5000
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow containers to reach the internet (to pull images/updates)
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"] # Required to pull images and for other outbound traffic
  }
}

# Allow Express to call Flask on port 5000 by allowing traffic from the ECS tasks security group to itself on port 5000
resource "aws_security_group_rule" "allow_service_connect" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id # This is the SG attached to the ECS tasks
  source_security_group_id = aws_security_group.ecs_tasks.id # Allow traffic from tasks in the same SG (i.e., Express can call Flask)
}

