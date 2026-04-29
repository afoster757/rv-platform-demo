output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "api_alb_dns_name" {
  value = module.api.alb_dns_name
}

output "ecr_repository_url" {
  value = module.api.ecr_repository_url
}

output "database_endpoint" {
  value = module.database.database_endpoint
}

output "redis_endpoint" {
  value = module.database.redis_endpoint
}
