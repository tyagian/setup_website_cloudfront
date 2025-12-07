# CloudFront Complete Project - Deployment Guide

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (version >= 1.0)
3. **Domain registered** through Route 53 (this creates the hosted zone automatically)

## Important: Route 53 Domain Registration Workflow

**CRITICAL**: You must register your domain through Route 53 FIRST before running Terraform. Here's why:

1. **Domain Registration**: When you register a domain through Route 53, AWS automatically creates a hosted zone
2. **DNS Propagation**: The domain needs time to propagate globally (24-48 hours)
3. **Certificate Validation**: ACM can only validate certificates once DNS is resolving

### Step 1: Register Domain (Manual Step)

Register your domain through Route 53 console or CLI:

```bash
# Option 1: AWS Console
# Go to Route 53 → Registered domains → Register domain

# Option 2: AWS CLI (example)
aws route53domains register-domain \
  --domain-name your-domain.com \
  --duration-in-years 1 \
  --admin-contact file://contact.json \
  --registrant-contact file://contact.json \
  --tech-contact file://contact.json
```

**Wait for domain registration to complete** before proceeding to Terraform deployment.

### Step 2: Verify DNS Propagation

Before running Terraform, verify your domain is resolving:

```bash
# Check if domain nameservers are propagating
dig NS your-domain.com

# Should return AWS nameservers like:
# ns-xxx.awsdns-xx.com
# ns-xxx.awsdns-xx.net
# ns-xxx.awsdns-xx.org
# ns-xxx.awsdns-xx.co.uk
```

### Step 3: Deploy Infrastructure

1. **Clone and configure**:
```bash
cd cloudfront-complete-project
cp terraform.tfvars.example terraform.tfvars
```

2. **Update terraform.tfvars**:
```hcl
domain_name  = "your-domain.com"  # Use your registered domain
project_name = "my-cloudfront-project"
environment  = "prod"
```

3. **Deploy**:
```bash
terraform init
terraform plan
terraform apply
```

## Certificate Validation Process

The Terraform configuration will:

1. **Create ACM certificate** for your domain and *.domain
2. **Add DNS validation records** to your existing hosted zone
3. **Wait for validation** to complete automatically

If certificate validation fails:
- Ensure domain is fully propagated globally
- Check that DNS validation CNAME records were created correctly
- Wait up to 30 minutes for validation to complete

## Troubleshooting

### Certificate Stuck in "PENDING_VALIDATION"

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn YOUR_CERT_ARN

# Verify DNS validation records exist
dig CNAME _validation-record.your-domain.com

# Check domain propagation
dig NS your-domain.com @8.8.8.8
```

### Domain Not Resolving

If your domain isn't resolving globally:
1. Wait 24-48 hours for full propagation
2. Check with multiple DNS servers
3. Verify nameservers at your registrar match Route 53

## Post-Deployment

1. **Upload content** to S3 buckets:
   - Website content → `your-domain.com-website-content`
   - Videos → `your-domain.com-video-content`

2. **Test CloudFront distribution**:
   - Access your domain: `https://your-domain.com`
   - Check cache headers and performance

3. **Monitor**:
   - CloudWatch dashboard: `your-project-cloudfront-dashboard`
   - WAF metrics and logs

## Project Structure

```
cloudfront-complete-project/
├── main.tf                 # Main infrastructure
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Provider versions
├── monitoring.tf         # CloudWatch resources
├── modules/
│   └── cloudfront/       # CloudFront module
├── functions/
│   └── security-headers.js
└── terraform.tfvars.example
```

## Key Changes from Standard Approach

1. **Uses data source** for hosted zone instead of creating it
2. **Assumes domain is pre-registered** through Route 53
3. **Handles DNS validation** automatically once domain propagates
4. **Modern OAC security** instead of legacy OAI
5. **Cache policies** instead of forwarded_values

This approach ensures reliable certificate validation and follows AWS best practices for domain management.