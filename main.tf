provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
  alias   = "us-east-1"
}

# SES domian verification
resource "aws_ses_domain_identity" "this" {
  provider = aws.us-east-1
  domain   = var.domain_name
}

resource "aws_ses_domain_identity_verification" "this" {
  depends_on = [aws_route53_record.ses_verification]
  provider   = aws.us-east-1
  domain     = aws_ses_domain_identity.this.id
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.this.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.this.verification_token]
}

# SES DKIM verification
resource "aws_ses_domain_dkim" "this" {
  provider = aws.us-east-1
  domain   = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name = format(
    "%s._domainkey.%s",
    element(aws_ses_domain_dkim.this.dkim_tokens, count.index),
    var.domain_name,
  )
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# SES Mail From record
resource "aws_ses_domain_mail_from" "this" {
  provider         = aws.us-east-1
  domain           = aws_ses_domain_identity.this.domain
  mail_from_domain = "mail.${var.domain_name}"
}

# SPF validaton record
resource "aws_route53_record" "spf_mail_from" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}
