
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
resource "aws_subnet" "private_subnet1c_admin_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1c_admin_env"
  }
}

# Create 4th subnet - public
resource "aws_subnet" "private_subnet1d_nat_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1d_nat_env"
  }
}
