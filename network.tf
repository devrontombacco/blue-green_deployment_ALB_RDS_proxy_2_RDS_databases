

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

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
  cidr_block              = var.private_subnet_1a
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet1a_blue_env"
  }
}

# Create 2nd subnet - private
resource "aws_subnet" "private_subnet1b_green_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_1b
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet1b_green_env"
  }
}

# Create 3rd subnet - public
resource "aws_subnet" "public_subnet1c_admin_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.admin_subnet_1c
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1c_admin_env"
  }
}

# Create 4th subnet - public
resource "aws_subnet" "public_subnet1d_nat_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_1d
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1d_nat_env"
  }
}

# Create 5th subnet - public
resource "aws_subnet" "public_subnet1e_nat_env" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_1e
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "public_subnet1e_nat_env"
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

# Create 1st Elastic IP for 1st Nat Gateway
resource "aws_eip" "nat_eip1" {
  domain = "vpc"

  tags = {
    Name = "nat_-eip1"
  }
}

# Create 1st NAT Gateway in public subnet
resource "aws_nat_gateway" "nat_gtw1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = aws_subnet.public_subnet1d_nat_env.id

  tags = {
    Name = "nat_gtw1"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create 2nd Elastic IP for 2nd Nat Gateway
resource "aws_eip" "nat_eip2" {
  domain = "vpc"

  tags = {
    Name = "nat_-eip2"
  }
}

# Create 2nd NAT Gateway in public subnet
resource "aws_nat_gateway" "nat_gtw2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = aws_subnet.public_subnet1e_nat_env.id

  tags = {
    Name = "nat_gtw2"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gtw1.id
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
