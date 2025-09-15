
# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

# Create Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}

# Create 1st subnet - private
resource "aws_subnet" "private_subnet1a_blue_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet1a_blue_env"
  }
}

# Create 2nd subnet - private
resource "aws_subnet" "private_subnet1b_green_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet1b_green_env"
  }
}

# Create 3rd subnet - public
resource "aws_subnet" "public_subnet1c_admin_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1c_admin_env"
  }
}

# Create 4th subnet - public
resource "aws_subnet" "public_subnet1d_nat_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1d_nat_env"
  }
}

# Create Public Route Table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }

}


# Route Table Association - 3rd subnet - public
resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_subnet1c_admin_env.id
  route_table_id = aws_route_table.public_rt.id
}

# Route Table Association - 4th subnet - public 
resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_subnet1d_nat_env.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Elastic IP for Nat Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat_-eip"
  }
}

# Create NAT Gateway in public subnet
resource "aws_nat_gateway" "nat_gtw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1d_nat_env.id

  tags = {
    Name = "nat_gtw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gtw.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Route Table Association - 1st subnet - private
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_subnet1a_blue_env.id
  route_table_id = aws_route_table.private_rt.id
}

# Route Table Association - 2nd subnet - private
resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_subnet1b_green_env.id
  route_table_id = aws_route_table.private_rt.id
}

# Create fallback var for my_ip_address 
variable "my_ip_address" {
  type    = string
  default = "0.0.0.0/0" # fallback IP
}


# Create Security Group for Bastion Host 
resource "aws_security_group" "sg_bastion_host" {
  name        = "sg_bastion_host"
  description = "Allow inbound ssh traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
  tags = {
    Name = "sg_bastion_host"
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create Security Group for ALB
resource "aws_security_group" "sg_alb" {
  name        = "sg_alb"
  description = "Allow inbound http traffic"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "sg_alb"
  }

  ingress {
    description = "http from anywhere"
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

}

# Create Security Group for private EC2 instances
resource "aws_security_group" "sg_ec2_private" {
  name        = "sg_ec2_private"
  description = "Allow inbound http traffic from ALB"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "sg_ec2_private"
  }

  ingress {
    description     = "http from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create AMI data source
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create blue EC2 instance
resource "aws_instance" "blue_ec2" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet1a_blue_env.id
  tags = {
    Name = "blue_ec2"
  }
  vpc_security_group_ids = [aws_security_group.sg_ec2_private.id]
  key_name               = "MY_EC2_INSTANCE_KEYPAIR"

}

# Create green EC2 instance
resource "aws_instance" "green_ec2" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet1a_blue_env.id
  tags = {
    Name = "green_ec2"
  }
  vpc_security_group_ids = [aws_security_group.sg_ec2_private.id]
  key_name               = "MY_EC2_INSTANCE_KEYPAIR"

}

# Create Application Load Balancer 
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_subnet1d_nat_env.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Create Blue Target Group
resource "aws_lb_target_group" "blue-tg" {
  name        = "blue-tg"
  target_type = "instance"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main_vpc.id
}

# Create Green Target Group
resource "aws_lb_target_group" "green-tg" {
  name        = "green-tg"
  target_type = "instance"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main_vpc.id
}

# Register blue ec2 with blue Target Group
resource "aws_lb_target_group_attachment" "blue_tg_attachment" {
  target_group_arn = aws_lb_target_group.blue-tg.id
  target_id        = aws_instance.blue_ec2.id
  port             = 80
}

# Register green ec2 with green Target Group
resource "aws_lb_target_group_attachment" "green_tg_attachment" {
  target_group_arn = aws_lb_target_group.green-tg.id
  target_id        = aws_instance.green_ec2.id
  port             = 80
}

# Create listener for ALB
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue-tg.arn
  }
}

resource "aws_lb_listener_rule" "alb_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue-tg.arn
  }

  condition {
    path_pattern {
      values = ["/blue/*"]
    }
  }
}

# Create bastion host in public subnet
resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet1c_admin_env.id
  vpc_security_group_ids = [aws_security_group.sg_bastion_host.id]
  key_name               = "MY_EC2_INSTANCE_KEYPAIR"

  tags = {
    Name = "bastion_host"
  }
}

