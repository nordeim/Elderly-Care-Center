terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.name}"
}

locals {
  default_cache_behavior = {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id = var.origin_id
    forwarded_values = {
      query_string = var.forward_query_string
      cookies = {
        forward = var.forward_cookies ? "all" : "none"
      }
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  comment             = var.comment
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.price_class
  aliases             = var.aliases
  default_root_object = var.default_root_object

  origin {
    domain_name = var.origin_domain
    origin_id   = var.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = local.default_cache_behavior.allowed_methods
    cached_methods         = local.default_cache_behavior.cached_methods
    target_origin_id       = local.default_cache_behavior.target_origin_id
    viewer_protocol_policy = local.default_cache_behavior.viewer_protocol_policy
    compress               = local.default_cache_behavior.compress

    forwarded_values {
      query_string = local.default_cache_behavior.forwarded_values.query_string

      cookies {
        forward = local.default_cache_behavior.forwarded_values.cookies.forward
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = var.acm_certificate_arn == null
  }

  logging_config {
    include_cookies = false
    bucket          = var.log_bucket
    prefix          = "cloudfront/${var.name}/"
  }

  default_cache_behavior {
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    allowed_methods        = local.default_cache_behavior.allowed_methods
    cached_methods         = local.default_cache_behavior.cached_methods
    target_origin_id       = local.default_cache_behavior.target_origin_id
    viewer_protocol_policy = local.default_cache_behavior.viewer_protocol_policy
    compress               = local.default_cache_behavior.compress

    forwarded_values {
      query_string = local.default_cache_behavior.forwarded_values.query_string

      cookies {
        forward = local.default_cache_behavior.forwarded_values.cookies.forward
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  depends_on = [aws_cloudfront_origin_access_identity.this]
  tags       = var.tags
}
