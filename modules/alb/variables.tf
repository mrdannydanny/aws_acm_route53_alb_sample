variable "certificate_arn" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "launch_template_id" {
  type = string
}

variable "bucket" {
  type = string
}

variable "bucket_prefix" {
  type = string
}


variable "tags" {
  type = map(string)
}