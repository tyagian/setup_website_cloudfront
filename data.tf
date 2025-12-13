
# Data source to get the existing hosted zone (created automatically during domain registration)
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}
