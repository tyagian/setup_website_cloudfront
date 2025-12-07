resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  # Website content origin
  origin {
    domain_name              = var.website_bucket_domain_name
    origin_id                = "S3-Website"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }
  
  # Video content origin
  origin {
    domain_name              = var.video_bucket_domain_name
    origin_id                = "S3-Videos"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  web_acl_id          = var.waf_web_acl_arn
  price_class         = var.price_class
  
  aliases = var.domain_aliases
  
  # Cache behavior for images
  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    compress         = true
    
    cache_policy_id            = aws_cloudfront_cache_policy.static_assets.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = var.security_headers_policy_id
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  ordered_cache_behavior {
    path_pattern     = "*.png"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    compress         = true
    
    cache_policy_id            = aws_cloudfront_cache_policy.static_assets.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = var.security_headers_policy_id
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  # Cache behavior for CSS
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    compress         = true
    
    cache_policy_id            = aws_cloudfront_cache_policy.static_assets.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = var.security_headers_policy_id
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  # Cache behavior for JS
  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    compress         = true
    
    cache_policy_id            = aws_cloudfront_cache_policy.static_assets.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = var.security_headers_policy_id
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  # Cache behavior for videos - optimized for streaming
  ordered_cache_behavior {
    path_pattern     = "/videos/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Videos"
    compress         = false
    
    cache_policy_id            = aws_cloudfront_cache_policy.video_content.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = var.cors_headers_policy_id
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  # Default cache behavior for HTML pages
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Website"
    compress               = true
    
    cache_policy_id            = aws_cloudfront_cache_policy.html_content.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = var.security_headers_policy_id
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = length(var.geo_restriction_locations) > 0 ? "whitelist" : "none"
      locations        = var.geo_restriction_locations
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  logging_config {
    include_cookies = false
    bucket          = var.logs_bucket_domain_name
    prefix          = "cloudfront-logs/"
  }
  
  tags = var.tags
}

# Cache policies
resource "aws_cloudfront_cache_policy" "static_assets" {
  name        = "${var.project_name}-static-assets"
  comment     = "Cache policy for static assets (images, CSS, JS)"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1
  
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
    
    query_strings_config {
      query_string_behavior = "none"
    }
    
    headers_config {
      header_behavior = "none"
    }
    
    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "html_content" {
  name        = "${var.project_name}-html-content"
  comment     = "Cache policy for HTML content"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0
  
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
    
    query_strings_config {
      query_string_behavior = "none"
    }
    
    headers_config {
      header_behavior = "none"
    }
    
    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "video_content" {
  name        = "${var.project_name}-video-content"
  comment     = "Cache policy for video content"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0
  
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = false
    
    query_strings_config {
      query_string_behavior = "all"
    }
    
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method", "Range"]
      }
    }
    
    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# Data sources for managed policies
data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}