output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "site_bucket" {
  value = module.cdn.site_bucket
}

output "site_bucket_arn" {
  value = module.cdn.site_bucket_arn
}

output "site_bucket_regional_domain_name" {
  value = module.cdn.site_bucket_regional_domain_name
}

output "content_bucket" {
  value = module.cdn.content_bucket
}

output "content_bucket_regional_domain_name" {
  value = module.cdn.content_bucket_regional_domain_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}
