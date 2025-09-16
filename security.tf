
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
