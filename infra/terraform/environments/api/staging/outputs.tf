output "api_alb_dns_name" {
  value = module.api.alb_dns_name
}

output "api_cloudfront_domain" {
  value = aws_cloudfront_distribution.api.domain_name
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
