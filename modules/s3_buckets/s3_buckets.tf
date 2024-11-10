resource "aws_s3_bucket" "s3_main_alb_logs" {
  tags = var.tags
}