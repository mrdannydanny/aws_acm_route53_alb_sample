module "default_vpc" {
  source = "./modules/default_vpc"
}

module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
  domain_fqdn = module.route53.domain_fqdn
  tags        = var.tags
}

module "route53" {
  source                          = "./modules/route53"
  domain_name                     = var.domain_name
  domain_validation_options_array = module.acm.aws_acm_certificate
  aws_lb_zone_dns_name            = module.alb.aws_lb_zone_dns_name
  aws_lb_zone_id                  = module.alb.aws_lb_zone_id
  tags                            = var.tags
}

# wait the certificate to change its status to "Issued"
resource "null_resource" "wait_for_certificate" {
  triggers = {
    certificate_arn = module.acm.aws_acm_arn
  }

  provisioner "local-exec" {
    command = "until aws acm describe-certificate --certificate-arn ${self.triggers.certificate_arn} --query 'Certificate.Status' --output text | grep -w ISSUED; do echo 'Waiting for certificate to be issued'; sleep 30; done"
  }
}

module "security_groups" {
  source         = "./modules/security_groups"
  default_vpc_id = module.default_vpc.default_vpc_id
  depends_on     = [null_resource.wait_for_certificate]
  tags           = var.tags
}

module "launch_templates" {
  source                            = "./modules/launch_templates"
  launch_template_security_group_id = module.security_groups.launch_template_security_group_id
  depends_on                        = [null_resource.wait_for_certificate]
  tags                              = var.tags
}

module "s3_buckets" {
  source = "./modules/s3_buckets"
  tags                              = var.tags
  bucket_prefix                     = "main-lb"  
}

module "alb" {
  source                = "./modules/alb"
  certificate_arn       = module.acm.aws_acm_arn
  vpc_id                = module.default_vpc.default_vpc_id
  alb_security_group_id = module.security_groups.alb_sg_id
  launch_template_id    = module.launch_templates.launch_template_id
  bucket                = module.s3_buckets.s3_main_alb_logs_id # s3 where alb logs will be stored
  bucket_prefix         = "main-lb"                             # helps identifying in case multiple lbs exist
  tags                  = var.tags
}