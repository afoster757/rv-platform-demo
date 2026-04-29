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
  content_cdn_base_url = "https://${data.terraform_remote_state.core.outputs.content_bucket_regional_domain_name}"
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
  content_cdn_base_url = "https://${data.terraform_remote_state.core.outputs.content_bucket_regional_domain_name}"
}

# ── UNIFIED CLOUDFRONT (static site + API on one domain) ───
# Default behavior  → S3 site bucket (OAC, cached)
# /healthz          → primary ALB (uncached)
# /readyz           → primary ALB (uncached)
# /v1/*             → primary ALB (uncached, all methods)

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.name}-${var.environment}-site-oac"
  description                       = "OAC for static site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "site" {
  bucket = data.terraform_remote_state.core.outputs.site_bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${data.terraform_remote_state.core.outputs.site_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "${var.name}-${var.environment}"
  default_root_object = "index.html"

  # S3 origin — static site
  origin {
    domain_name              = data.terraform_remote_state.core.outputs.site_bucket_regional_domain_name
    origin_id                = "site-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # ALB origin — API
  origin {
    domain_name = module.api.alb_dns_name
    origin_id   = "api-alb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default: static site from S3 (GET/HEAD only, cached)
  default_cache_behavior {
    target_origin_id       = "site-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # /healthz → ALB
  ordered_cache_behavior {
    path_pattern           = "/healthz"
    target_origin_id       = "api-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
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

  # /readyz → ALB
  ordered_cache_behavior {
    path_pattern           = "/readyz"
    target_origin_id       = "api-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
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

  # /v1/* → ALB (all methods, no cache)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "api-alb"
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
