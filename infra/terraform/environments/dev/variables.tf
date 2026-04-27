variable "aws_region" { type = string default = "us-east-1" }
variable "name" { type = string default = "rv-platform-demo" }
variable "environment" { type = string default = "dev" }
variable "image_tag" { type = string default = "latest" }
variable "database_url" { type = string sensitive = true default = "postgres://placeholder:placeholder@example.com:5432/rvdemo" }
variable "redis_addr" { type = string default = "placeholder.redis.example.com:6379" }
variable "vpc_cidr" { type = string default = "10.20.0.0/16" }
variable "azs" { type = list(string) default = ["us-east-1a", "us-east-1b"] }
variable "public_subnet_cidrs" { type = list(string) default = ["10.20.1.0/24", "10.20.2.0/24"] }
variable "private_subnet_cidrs" { type = list(string) default = ["10.20.11.0/24", "10.20.12.0/24"] }
