output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = module.cloudfront.distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Distribution Hosted Zone ID"
  value       = module.cloudfront.distribution_hosted_zone_id
}

output "website_bucket_name" {
  description = "S3 Bucket Name for website content"
  value       = aws_s3_bucket.website_content.bucket
}

output "website_bucket_arn" {
  description = "S3 Bucket ARN for website content"
  value       = aws_s3_bucket.website_content.arn
}

output "video_bucket_name" {
  description = "S3 Bucket Name for video content"
  value       = aws_s3_bucket.video_content.bucket
}

output "video_bucket_arn" {
  description = "S3 Bucket ARN for video content"
  value       = aws_s3_bucket.video_content.arn
}

output "logs_bucket_name" {
  description = "S3 Bucket Name for CloudFront logs"
  value       = aws_s3_bucket.logs.bucket
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Route53 Name Servers (update your domain registrar with these)"
  value       = data.aws_route53_zone.main.name_servers
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.main.arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "origin_access_control_id" {
  description = "Origin Access Control ID"
  value       = module.cloudfront.origin_access_control_id
}

output "website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}

output "www_website_url" {
  description = "WWW Website URL"
  value       = "https://www.${var.domain_name}"
}