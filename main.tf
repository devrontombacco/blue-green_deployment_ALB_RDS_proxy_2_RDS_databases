
# Create fallback var for my_ip_address 
variable "my_ip_address" {
  type    = string
  default = "0.0.0.0/0" # fallback IP
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
  user_data              = base64encode(templatefile("user_data.sh", {}))
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
  user_data              = base64encode(templatefile("user_data.sh", {}))
}

# Create Application Load Balancer 
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_subnet1d_nat_env.id, aws_subnet.public_subnet1e_nat_env.id]

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
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
}

# Create Green Target Group
resource "aws_lb_target_group" "green-tg" {
  name        = "green-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
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

