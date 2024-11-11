variable "tags" {
  type = map(string)
}

variable "bucket_prefix" {
  type = string
  default = "test"
}