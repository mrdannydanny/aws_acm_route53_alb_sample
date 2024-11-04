variable "domain_name" {
  type = string
}

variable "domain_validation_options_array" {
 type = list 
}

variable "aws_lb_zone_id" {
  type = string
}

variable "aws_lb_zone_dns_name" {
  type = string
}