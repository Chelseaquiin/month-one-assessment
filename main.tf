provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "techcorp_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "techcorp-vpc"
  }
}
# Get availability zones
data "aws_availability_zones" "available" {}

# Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.techcorp_vpc.id

  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch = true

  tags = {
    Name = "techcorp-public-subnet-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.techcorp_vpc.id

  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  map_public_ip_on_launch = true

  tags = {
    Name = "techcorp-public-subnet-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.techcorp_vpc.id

  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "techcorp-private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.techcorp_vpc.id

  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "techcorp-private-subnet-2"
  }
}
# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = {
    Name = "techcorp-igw"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "techcorp-public-rt"
  }
}

# Associate public subnets

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}
# Elastic IPs

resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
}

# NAT Gateway 1

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "techcorp-nat-1"
  }
}

# NAT Gateway 2

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "techcorp-nat-2"
  }
}
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}
# Bastion SG

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public_subnet_1.id

  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "techcorp-bastion"
  }
}

####################################
# WEB SECURITY GROUP
####################################

resource "aws_security_group" "web_sg" {

  name   = "web-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {

    description = "HTTP"

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    description = "HTTPS"

    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    description = "SSH from Bastion"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    security_groups = [
      aws_security_group.bastion_sg.id
    ]

  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "techcorp-web-sg"
  }

}

####################################
# DATABASE SECURITY GROUP
####################################

resource "aws_security_group" "db_sg" {

  name   = "db-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {

    description = "Postgres from Web"

    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    security_groups = [
      aws_security_group.web_sg.id
    ]

  }

  ingress {

    description = "SSH from Bastion"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    security_groups = [
      aws_security_group.bastion_sg.id
    ]

  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "techcorp-db-sg"
  }

}

####################################
# WEB SERVERS (2 INSTANCES)
####################################

resource "aws_instance" "web" {

  count = 2

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.web_instance_type

  subnet_id = element([
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ], count.index)

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  key_name = var.key_name

  user_data = file("user_data/web_server_setup.sh")

  tags = {
    Name = "techcorp-web-${count.index + 1}"
  }
}

####################################
# DATABASE SERVER
####################################

resource "aws_instance" "database" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.db_instance_type

  subnet_id = aws_subnet.private_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.db_sg.id
  ]

  key_name = var.key_name

  user_data = file("user_data/db_server_setup.sh")

  tags = {
    Name = "techcorp-database"
  }
}
####################################
# TARGET GROUP
####################################

resource "aws_lb_target_group" "web_tg" {

  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"

  vpc_id = aws_vpc.techcorp_vpc.id

  health_check {
    path = "/"
    port = "80"
  }

}
####################################
# ATTACH WEB SERVERS
####################################

resource "aws_lb_target_group_attachment" "web_attach" {

  count = 2

  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web[count.index].id
  port              = 80

}

####################################
# LOAD BALANCER LISTENER
####################################

resource "aws_lb_listener" "listener" {

  load_balancer_arn = aws_lb.alb.arn

  port     = "80"
  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.web_tg.arn

  }

}
####################################
# APPLICATION LOAD BALANCER
####################################

resource "aws_lb" "alb" {

  name = "techcorp-alb"

  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  security_groups = [
    aws_security_group.web_sg.id
  ]

}
