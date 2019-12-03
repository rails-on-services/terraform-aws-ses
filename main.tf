# SES domian verification
resource "aws_ses_domain_identity" "this" {
  domain = var.domain_name
}

resource "aws_ses_domain_identity_verification" "this" {
  depends_on = [aws_route53_record.ses_verification]
  domain = aws_ses_domain_identity.this.id
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.this.id}"
  type    = "TXT"
  ttl     = "60"
  records = [aws_ses_domain_identity.this.verification_token]
}

# SES DKIM verification

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
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