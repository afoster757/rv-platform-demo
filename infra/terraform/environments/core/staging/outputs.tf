output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "cloudfront_domain" {
  value = module.cdn.cloudfront_domain
}

output "cloudfront_distribution_id" {
  value = module.cdn.cloudfront_distribution_id
}

output "site_bucket" {
  value = module.cdn.site_bucket
}

output "content_bucket" {
  value = module.cdn.content_bucket
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}
