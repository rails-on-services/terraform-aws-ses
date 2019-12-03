variable "domain_name" {
  type        = string
  description = "The domain name for the SES account"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID to add verification records into"
}