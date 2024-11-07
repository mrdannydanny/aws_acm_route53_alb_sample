# creates an ACM certificate
resource "aws_acm_certificate" "domain_certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# validates the certificate and the record created on route 53
resource "aws_acm_certificate_validation" "domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.domain_certificate.arn
  validation_record_fqdns = [var.domain_fqdn]
}

