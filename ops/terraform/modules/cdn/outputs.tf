output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  description = "CloudFront domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "origin_access_identity" {
  description = "CloudFront origin access identity path."
  value       = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
}
