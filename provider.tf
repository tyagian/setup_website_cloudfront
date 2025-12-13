provider "aws" {
  region = var.aws_region
}

# Provider for us-east-1 (required for CloudFront resources)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}