# create an s3 bucket
resource "aws_s3_bucket" "s3_main_alb_logs" {
  tags = var.tags
}

# get IAM user ID
data "aws_caller_identity" "current" {}

# get the ID number of load balancer in the AWS region you are using 
# full list can be found here: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
data "aws_elb_service_account" "main" {} 

# type of encryption for the bucket (check if it can be removed)
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_encryption" {
  bucket = "${aws_s3_bucket.s3_main_alb_logs.bucket}"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# policy to allow the load balancer to write to s3 bucket created in this module
data "aws_iam_policy_document" "allow_load_balancer_write" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.s3_main_alb_logs.arn}/${var.bucket_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
  }
}

# attaches the policy to the bucket
resource "aws_s3_bucket_policy" "access_logs" {
    bucket = "${aws_s3_bucket.s3_main_alb_logs.id}"
    policy = data.aws_iam_policy_document.allow_load_balancer_write.json
}