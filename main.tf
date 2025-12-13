# Random suffix for unique resource names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}


# S3 bucket for website content (HTML, CSS, JS, images)
resource "aws_s3_bucket" "website_content" {
  bucket = "${var.domain_name}-website-content"
  
  tags = {
    Name        = "${var.project_name}-website-content"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "website_content" {
  bucket = aws_s3_bucket.website_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "website_content" {
  bucket = aws_s3_bucket.website_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket for video content
resource "aws_s3_bucket" "video_content" {
  bucket = "${var.domain_name}-video-content"
  
  tags = {
    Name        = "${var.project_name}-video-content"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "video_content" {
  bucket = aws_s3_bucket.video_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.domain_name}-cloudfront-logs-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
  
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 bucket policy for website content (using OAC)
resource "aws_s3_bucket_policy" "website_content" {
  bucket = aws_s3_bucket.website_content.id
  
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.website_content.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = module.cloudfront.distribution_arn
        }
      }
    }]
  })
  
  depends_on = [module.cloudfront]
}

# S3 bucket policy for video content (using OAC)
resource "aws_s3_bucket_policy" "video_content" {
  bucket = aws_s3_bucket.video_content.id
  
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.video_content.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = module.cloudfront.distribution_arn
        }
      }
    }]
  })
  
  depends_on = [module.cloudfront]
}

# ACM certificate (must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "main" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}

# DNS validation record
resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_value]
  ttl             = 60
  type            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "main" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "main" {
  provider = aws.us_east_1
  name     = "${var.project_name}-waf"
  scope    = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            allow {}
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }
  
  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 3
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}WAF"
    sampled_requests_enabled   = true
  }
  
  tags = {
    Name        = "${var.project_name}-waf"
    Environment = var.environment
  }
}

# Response headers policies
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.project_name}-security-headers"
  
  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    
    content_type_options {
      override = true
    }
    
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
  

}

resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name = "${var.project_name}-cors-policy"
  
  cors_config {
    access_control_allow_credentials = false
    
    access_control_allow_headers {
      items = ["*"]
    }
    
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }
    
    access_control_allow_origins {
      items = ["*"]
    }
    
    origin_override = true
  }
}



# CloudFront distribution using module
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name                = var.project_name
  website_bucket_domain_name  = aws_s3_bucket.website_content.bucket_regional_domain_name
  video_bucket_domain_name    = aws_s3_bucket.video_content.bucket_regional_domain_name
  logs_bucket_domain_name     = aws_s3_bucket.logs.bucket_domain_name
  domain_aliases              = [var.domain_name, "www.${var.domain_name}"]
  acm_certificate_arn         = aws_acm_certificate_validation.main.certificate_arn
  waf_web_acl_arn            = aws_wafv2_web_acl.main.arn
  security_headers_policy_id  = aws_cloudfront_response_headers_policy.security_headers.id
  cors_headers_policy_id      = aws_cloudfront_response_headers_policy.cors_policy.id
  price_class                 = var.price_class
  geo_restriction_locations   = var.geo_restriction_locations
  
  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}

# Route53 records for the domain
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

# distribution alias domain 
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}