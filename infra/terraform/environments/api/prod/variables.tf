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
