# Complete CloudFront Project with Terraform

This Terraform project creates a production-ready AWS CloudFront distribution using modern AWS practices including Origin Access Control (OAC), cache policies, and modular architecture.

## Architecture Overview

The project creates:
- **CloudFront Distribution** with custom domain and SSL using modular approach
- **Multiple S3 Origins**: Separate buckets for website content and videos
- **Modern Security**: OAC (not legacy OAI), WAF with managed rules, optional Shield Advanced
- **Cache Policies**: Modern caching approach replacing forwarded_values
- **DNS Management**: Route53 hosted zone with domain records
- **Monitoring**: CloudWatch dashboard and comprehensive alarms
- **Response Headers**: Security and CORS policies

## Key Modern Features

### Origin Access Control (OAC)
- Replaces legacy Origin Access Identity (OAI)
- Enhanced security with AWS Signature Version 4 (SigV4)
- Support for S3 server-side encryption with AWS KMS
- Better integration with AWS services

### Cache Policies
- Modern approach replacing forwarded_values
- Better performance and granular control
- Separate policies for different content types
- Built-in compression and encoding support

### Modular Architecture
- Reusable CloudFront module
- Clean separation of concerns
- Easy to maintain and extend
- Production-ready structure

## ⚠️ IMPORTANT: Prerequisites

**You MUST register your domain through Route 53 FIRST** before running Terraform. 

1. Domain registration automatically creates the hosted zone
2. DNS propagation is required for SSL certificate validation
3. Certificate validation will fail if domain isn't globally resolvable

### Required:
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- **Domain registered through Route 53** (creates hosted zone automatically)

## Required AWS Permissions

Your AWS user/role needs permissions for:
- CloudFront (full access)
- S3 (full access)
- Route53 (full access)
- ACM (full access)
- WAF (full access)
- CloudWatch (dashboard and metrics access)

## Deployment Workflow

### Phase 1: Domain Registration (Manual)

1. **Register domain through Route 53**:
   ```bash
   # Option 1: AWS Console - Route 53 → Registered domains → Register domain
   
   # Option 2: AWS CLI
   aws route53domains register-domain \
     --domain-name your-domain.com \
     --duration-in-years 1
   ```

2. **Wait for DNS propagation** (24-48 hours):
   ```bash
   # Verify domain is resolving
   dig NS your-domain.com
   # Should return AWS nameservers
   ```

### Phase 2: Infrastructure Deployment

1. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your REGISTERED domain
   ```

2. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Certificate validation**: Happens automatically once DNS propagates

### Phase 3: Content Upload

1. Upload website files to the website content bucket
2. Upload videos to the video content bucket
3. Test your CloudFront distribution at `https://your-domain.com`

## Configuration

### Required Variables

- `domain_name`: Your domain (e.g., "example.com")
- `project_name`: Project name for resource naming

### Optional Variables

- `aws_region`: AWS region (default: "us-east-1")
- `environment`: Environment name (default: "prod")
- `price_class`: CloudFront price class (default: "PriceClass_200")
- `enable_shield_advanced`: Enable Shield Advanced (default: false)

### Price Classes

- **PriceClass_100**: US, Canada, Europe (lowest cost)
- **PriceClass_200**: Adds Asia, Middle East, Africa (recommended)
- **PriceClass_All**: All edge locations globally (highest performance)

## Project Structure

```
cloudfront-complete-project/
├── main.tf                    # Main configuration with module calls
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── monitoring.tf              # CloudWatch dashboard and alarms
├── terraform.tfvars.example   # Example configuration
├── versions.tf                # Provider requirements
├── README.md                  # This file
└── modules/
    └── cloudfront/
        ├── main.tf            # CloudFront module implementation
        ├── variables.tf       # Module variables
        └── outputs.tf         # Module outputs
```

## Content Upload

After deployment, upload your content to the S3 buckets:

### Website Content Bucket
Upload HTML, CSS, JS, and image files:
```bash
aws s3 sync ./website-files s3://$(terraform output -raw website_bucket_name)/
```

### Video Content Bucket
Upload video files to the `/videos/` path:
```bash
aws s3 sync ./video-files s3://$(terraform output -raw video_bucket_name)/videos/
```

## Cache Behaviors

The distribution includes optimized cache policies:

| Content Type | Path Pattern | Cache Policy | TTL | Compression |
|-------------|-------------|-------------|-----|-------------|
| Images | `*.{jpg,png,gif,etc}` | static_assets | 1 year | Yes |
| CSS/JS | `*.{css,js,woff,etc}` | static_assets | 1 year | Yes |
| Videos | `/videos/*` | video_content | 1 day | No |
| HTML | Default | html_content | 1 hour | Yes |

## Security Features

- **Origin Access Control (OAC)**: Modern secure S3 access
- **WAF Protection**: Blocks common attacks and implements rate limiting
- **SSL/TLS**: Custom domain with ACM certificate
- **Security Headers**: HSTS, CSP, X-Frame-Options via response headers policy
- **Shield Standard**: Built-in DDoS protection
- **Shield Advanced**: Optional premium protection

## Monitoring

The project includes:
- **CloudWatch Dashboard**: Performance metrics and error rates
- **CloudWatch Alarms**: 
  - High 4xx error rate (>5%)
  - High 5xx error rate (>1%)
  - Low cache hit rate (<80%)
  - High origin latency (>3 seconds)
- **Access Logs**: Detailed request logs stored in S3

## Load Balancer Integration

To add dynamic content origins (ALB, API Gateway), add this to your module call:

```hcl
# In main.tf, add additional origin to the module
# You can extend the module to support custom origins
```

## Outputs

After deployment, you'll get:
- CloudFront distribution ID and domain
- S3 bucket names for content upload
- Route53 nameservers (update your domain registrar)
- Website URLs (https://yourdomain.com)

## Cost Considerations

- **CloudFront**: Pay per request and data transfer
- **S3**: Storage and request costs
- **Route53**: $0.50/month per hosted zone
- **ACM**: SSL certificates are free
- **WAF**: $1/month + $0.60 per million requests
- **Shield Advanced**: $3,000/month (optional)

## Migration from Legacy Setup

If you're migrating from an older CloudFront setup:

### From OAI to OAC
- The project uses modern OAC instead of legacy OAI
- Better security and performance
- Supports S3 encryption with KMS

### From forwarded_values to Cache Policies
- Modern cache policies replace forwarded_values
- Better performance and control
- Easier to manage and maintain

## Troubleshooting

### Certificate Validation Issues

If certificate stays in "PENDING_VALIDATION":

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn YOUR_CERT_ARN

# Verify DNS validation records
dig CNAME _validation-record.your-domain.com

# Check global DNS propagation
dig NS your-domain.com @8.8.8.8
```

**Solution**: Wait for full DNS propagation (up to 48 hours for new domains)
- Certificate validation can take 5-30 minutes AFTER domain propagates

### CloudFront Deployment Time
- Initial distribution deployment takes 15-20 minutes
- Updates take 10-15 minutes to propagate

### Content Not Loading
- Check S3 bucket policies and OAC configuration
- Verify content is uploaded to correct bucket paths
- Check CloudFront cache behaviors and origins

### Module Issues
- Ensure all module variables are properly set
- Check module outputs are correctly referenced
- Verify module path is correct

## Cleanup

To destroy all resources:
```bash
# Empty S3 buckets first
aws s3 rm s3://$(terraform output -raw website_bucket_name) --recursive
aws s3 rm s3://$(terraform output -raw video_bucket_name) --recursive
aws s3 rm s3://$(terraform output -raw logs_bucket_name) --recursive

# Destroy infrastructure
terraform destroy
```

## Support

For issues or questions:
- Check AWS CloudFront documentation
- Review Terraform AWS provider documentation
- Verify your AWS permissions and quotas
- Check module configuration and outputs

## License

This project is provided as-is for educational and production use.