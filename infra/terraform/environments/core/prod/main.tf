terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "network" {
  source               = "../../../modules/network"
  name                 = var.name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "cdn" {
  source      = "../../../modules/cdn"
  name        = var.name
  environment = var.environment
}

resource "aws_ecr_repository" "api" {
  name                 = "${var.name}-${var.environment}-api"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
