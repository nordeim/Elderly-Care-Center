variable "name" {
  description = "Unique identifier for the CDN distribution."
  type        = string
}

variable "origin_domain" {
  description = "Domain name of the S3 bucket or custom origin."
  type        = string
}

variable "origin_id" {
  description = "Identifier for the origin configuration."
  type        = string
}

variable "aliases" {
  description = "List of alternate domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "Default root object for viewer requests."
  type        = string
  default     = "index.html"
}

variable "comment" {
  description = "Description for the CloudFront distribution."
  type        = string
  default     = "Elderly Daycare CDN Distribution"
}

variable "forward_query_string" {
  description = "Whether to forward query strings to the origin."
  type        = bool
  default     = false
}

variable "forward_cookies" {
  description = "Whether to forward cookies to the origin."
  type        = bool
  default     = false
}

variable "log_bucket" {
  description = "S3 bucket for CloudFront access logs (must include domain suffix)."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version supported."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "price_class" {
  description = "CloudFront price class for distribution."
  type        = string
  default     = "PriceClass_100"
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects."
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for cached objects."
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects."
  type        = number
  default     = 31536000
}

variable "custom_error_responses" {
  description = "List of custom error responses."
  type = list(object({
    error_code            = number
    response_page_path    = string
    response_code         = string
    error_caching_min_ttl = number
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the CloudFront distribution."
  type        = map(string)
  default     = {}
}
