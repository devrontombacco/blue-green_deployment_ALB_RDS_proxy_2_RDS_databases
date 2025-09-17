
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the main VPC"
}

variable "instance_type" {
  type        = string
  description = "Type of ec2"
}

variable "key_name" {
  type        = string
  description = "key name for ec2"
}

variable "private_subnet_1a" {
  type        = string
  description = "cider block for first privae subnet "
}

variable "private_subnet_1b" {
  type        = string
  description = "cider block for second private  subnet "
}
variable "admin_subnet_1c" {
  type        = string
  description = "cider block for admin subnet"
}

variable "public_subnet_1d" {
  type        = string
  description = "cider block for public subnet d "
}

variable "public_subnet_1e" {
  type        = string
  description = "cider block for piblic subnet e"
}
