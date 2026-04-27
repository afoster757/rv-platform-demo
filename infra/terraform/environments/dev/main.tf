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

# In a real production implementation, the database module would be connected to
# the API service security group and DATABASE_URL would be supplied through AWS
# Secrets Manager. For interview demo clarity, this root accepts database_url as
# a sensitive variable so plans remain easy to inspect without provisioning RDS.
module "api" {
  source               = "../../modules/ecs-api"
  name                 = var.name
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids
  image_tag            = var.image_tag
  database_url         = var.database_url
  redis_addr           = var.redis_addr
  content_cdn_base_url = "https://${module.cdn.cloudfront_domain}/content"
}
