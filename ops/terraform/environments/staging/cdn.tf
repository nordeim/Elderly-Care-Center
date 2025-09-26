module "cdn" {
  source = "../../modules/cdn"

  name                 = "elderly-daycare-staging"
  origin_domain        = var.media_bucket_domain
  origin_id            = "elderly-daycare-media"
  aliases              = ["media-staging.elderlydaycare.test"]
  default_root_object  = "index.html"
  comment              = "Elderly Daycare CDN (staging)"
  forward_query_string = false
  forward_cookies      = false
  log_bucket           = var.log_bucket
  acm_certificate_arn  = var.acm_certificate_arn
  price_class          = "PriceClass_100"
  min_ttl              = 0
  default_ttl          = 86400
  max_ttl              = 31536000
  tags = {
    Environment = "staging"
    Service     = "elderly-daycare"
  }
}

output "cdn_domain" {
  description = "CDN domain name for staging environment."
  value       = module.cdn.domain_name
}
