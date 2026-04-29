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

# Primary region (us-east-1)
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

# Secondary region (us-west-2)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
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

# ── PRIMARY REGION (us-east-1) ──────────────────────────────

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
  database_url         = "postgres://rvdemo:${urlencode(module.database.database_password_secret_value)}@${module.database.database_endpoint}:5432/rvdemo"
  redis_addr           = "${module.database.redis_endpoint}:6379"
  content_cdn_base_url = "https://${data.terraform_remote_state.core.outputs.cloudfront_domain}/content"
}

# ── SECONDARY REGION (us-west-2) ───────────────────────────

module "network_secondary" {
  source = "../../../modules/network"
  providers = {
    aws = aws.secondary
  }
  name                 = var.name
  cidr                 = var.secondary_vpc_cidr
  azs                  = var.secondary_azs
  public_subnet_cidrs  = var.secondary_public_subnet_cidrs
  private_subnet_cidrs = var.secondary_private_subnet_cidrs
}

module "database_secondary" {
  source = "../../../modules/database"
  providers = {
    aws    = aws.secondary
    random = random
  }
  name                       = var.name
  environment                = var.environment
  vpc_id                     = module.network_secondary.vpc_id
  private_subnet_ids         = module.network_secondary.private_subnet_ids
  allowed_security_group_ids = [module.api_secondary.api_security_group_id]
}

module "api_secondary" {
  source = "../../../modules/ecs-api"
  providers = {
    aws = aws.secondary
  }
  name                 = var.name
  environment          = var.environment
  name_suffix          = "-secondary"
  vpc_id               = module.network_secondary.vpc_id
  public_subnet_ids    = module.network_secondary.public_subnet_ids
  private_subnet_ids   = module.network_secondary.private_subnet_ids
  image_tag            = var.image_tag
  ecr_repository_url   = data.terraform_remote_state.core.outputs.ecr_repository_url
  database_url         = "postgres://rvdemo:${urlencode(module.database_secondary.database_password_secret_value)}@${module.database_secondary.database_endpoint}:5432/rvdemo"
  redis_addr           = "${module.database_secondary.redis_endpoint}:6379"
  content_cdn_base_url = "https://${data.terraform_remote_state.core.outputs.cloudfront_domain}/content"
}

# ── API CLOUDFRONT (HTTPS proxy → primary ALB) ─────────────
# CloudFront origin groups do not support write methods (POST/PUT/PATCH/DELETE).
# Regional failover for write traffic uses Route 53 health-check failover routing.
# CloudFront here provides HTTPS termination to resolve browser mixed-content policy.

resource "aws_cloudfront_distribution" "api" {
  enabled = true
  comment = "${var.name}-${var.environment} API"

  origin {
    domain_name = module.api.alb_dns_name
    origin_id   = "api-primary-${var.aws_region}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "api-primary-${var.aws_region}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    forwarded_values {
      query_string = true
      headers      = ["Accept", "Authorization", "Content-Type", "Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
