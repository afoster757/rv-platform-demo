variable "name" {
  type = string
}

variable "environment" {
  type = string
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.name}-${var.environment}-site"
}

resource "aws_s3_bucket" "content" {
  bucket = "${var.name}-${var.environment}-content"
}

resource "aws_s3_bucket_versioning" "content" {
  bucket = aws_s3_bucket.content.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "content" {
  bucket                  = aws_s3_bucket.content.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "site_bucket" {
  value = aws_s3_bucket.site.bucket
}

output "site_bucket_arn" {
  value = aws_s3_bucket.site.arn
}

output "site_bucket_regional_domain_name" {
  value = aws_s3_bucket.site.bucket_regional_domain_name
}

output "content_bucket" {
  value = aws_s3_bucket.content.bucket
}

output "content_bucket_regional_domain_name" {
  value = aws_s3_bucket.content.bucket_regional_domain_name
}
