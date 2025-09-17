
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
