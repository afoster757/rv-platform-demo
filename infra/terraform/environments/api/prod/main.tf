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

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "rv-terraform-state-afoster"
    key    = "rv-platform-demo/${var.environment}/core/terraform.tfstate"
    region = "us-east-1"
  }
}

module "database" {
  source                     = "../../../modules/database"
  name                       = var.name
  environment                = var.environment
  vpc_id                     = data.terraform_remote_state.core.outputs.vpc_id
  private_subnet_ids         = data.terraform_remote_state.core.outputs.private_subnet_ids
  allowed_security_group_ids = [module.api.api_security_group_id]
}

module "api" {
  source               = "../../../modules/ecs-api"
  name                 = var.name
  environment          = var.environment
  vpc_id               = data.terraform_remote_state.core.outputs.vpc_id
  public_subnet_ids    = data.terraform_remote_state.core.outputs.public_subnet_ids
  private_subnet_ids   = data.terraform_remote_state.core.outputs.private_subnet_ids
  image_tag            = var.image_tag
  ecr_repository_url   = data.terraform_remote_state.core.outputs.ecr_repository_url
  database_url         = "postgres://rvdemo:${module.database.database_password_secret_value}@${module.database.database_endpoint}:5432/rvdemo"
  redis_addr           = "${module.database.redis_endpoint}:6379"
  content_cdn_base_url = "https://${data.terraform_remote_state.core.outputs.cloudfront_domain}/content"
}
