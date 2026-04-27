output "api_alb_dns_name" { value = module.api.alb_dns_name }
output "site_cloudfront_domain" { value = module.cdn.cloudfront_domain }
output "site_bucket" { value = module.cdn.site_bucket }
output "content_bucket" { value = module.cdn.content_bucket }
output "ecr_repository_url" { value = module.api.ecr_repository_url }
