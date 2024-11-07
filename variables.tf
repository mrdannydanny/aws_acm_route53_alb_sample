variable "domain_name" {
  type    = string
  default = "dannyops.space"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "ops"
  }
}