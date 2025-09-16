
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
