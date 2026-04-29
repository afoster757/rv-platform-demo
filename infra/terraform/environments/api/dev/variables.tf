variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "rv-platform-demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "secondary_region" {
  type    = string
  default = "us-west-2"
}

variable "secondary_vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "secondary_azs" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "secondary_public_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
}

variable "secondary_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
}
