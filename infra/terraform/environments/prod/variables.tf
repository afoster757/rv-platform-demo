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
  default = "prod"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "vpc_cidr" {
  type    = string
  default = "10.22.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.22.1.0/24", "10.22.2.0/24", "10.22.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.22.11.0/24", "10.22.12.0/24", "10.22.13.0/24"]
}
