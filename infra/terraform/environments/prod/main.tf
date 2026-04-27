terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
  source               = "../../modules/network"
  name                 = var.name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "cdn" {
  source      = "../../modules/cdn"
  name        = var.name
  environment = var.environment
}

module "database" {
  source                     = "../../modules/database"
  name                       = var.name
  environment                = var.environment
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [module.api.api_security_group_id]
}

module "api" {
  source               = "../../modules/ecs-api"
  name                 = var.name
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids
  image_tag            = var.image_tag
  database_url         = "postgres://rvdemo:${module.database.database_password_secret_value}@${module.database.database_endpoint}:5432/rvdemo"
  redis_addr           = "${module.database.redis_endpoint}:6379"
  content_cdn_base_url = "https://${module.cdn.cloudfront_domain}/content"
}
