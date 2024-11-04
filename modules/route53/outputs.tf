output "domain_fqdn" {
  value = aws_route53_record.domain_cname_dns_record.fqdn
}