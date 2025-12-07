variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "website_bucket_domain_name" {
  description = "Domain name of the website S3 bucket"
  type        = string
}

variable "video_bucket_domain_name" {
  description = "Domain name of the video S3 bucket"
  type        = string
}

variable "logs_bucket_domain_name" {
  description = "Domain name of the logs S3 bucket"
  type        = string
}

variable "domain_aliases" {
  description = "List of domain aliases for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  type        = string
}

variable "security_headers_policy_id" {
  description = "ID of the security headers response policy"
  type        = string
}

variable "cors_headers_policy_id" {
  description = "ID of the CORS headers response policy"
  type        = string
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_200"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction (empty list = no restriction)"
  type        = list(string)
  default     = ["US"]
}