output "aws_acm_certificate" {
  value = aws_acm_certificate.domain_certificate.domain_validation_options
}

output "aws_acm_arn" {
  value = aws_acm_certificate.domain_certificate.arn
}