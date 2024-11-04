# creates a public hosted zone on route 53
resource "aws_route53_zone" "domain_public_zone" {
  name = var.domain_name
}

# creates a CNAME record for the domain specified in the variables.tf (domain_name variable)
resource "aws_route53_record" "domain_cname_dns_record" {
  allow_overwrite = true
  name =  tolist(var.domain_validation_options_array)[0].resource_record_name
  records = [tolist(var.domain_validation_options_array)[0].resource_record_value]
  type = tolist(var.domain_validation_options_array)[0].resource_record_type
  zone_id = aws_route53_zone.domain_public_zone.zone_id
  ttl = 60
}

# creates an alias record targeting the ALB
resource "aws_route53_record" "alias_to_lb" {
  zone_id = aws_route53_zone.domain_public_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.aws_lb_zone_dns_name
    zone_id                = var.aws_lb_zone_id
    evaluate_target_health = true
  }
}