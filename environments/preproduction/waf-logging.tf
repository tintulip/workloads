resource "aws_wafv2_web_acl_logging_configuration" "waf_logging_config" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_delivery_stream.arn]
  resource_arn            = aws_wafv2_web_acl.waf.arn
}

resource "aws_kinesis_firehose_delivery_stream" "waf_delivery_stream" {
  name        = "aws-waf-logs-firehose-stream"
  destination = "s3"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.waf_bucket.arn
    compression_format = "GZIP"
  }
}

resource "aws_s3_bucket" "waf_bucket" {
  #checkov:skip=CKV_AWS_52:Bucket is created by a pipeline
  #checkov:skip=CKV_AWS_18:Access logging needs to go into a cross account bucket
  #checkov:skip=CKV_AWS_144:Not required to have cross region enabled
  #checkov:skip=CKV_AWS_145:Cannot use KMS for cross-account log replication
  bucket = "waf-logging-${data.aws_caller_identity.preproduction.account_id}"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "log-expire"
    enabled = true

    tags = {
      rule      = "log-expire"
      autoclean = "true"
    }

    expiration {
      days = 30
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_bucket" {
  bucket = aws_s3_bucket.waf_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_iam_role" "firehose_role" {
  name = "waf-firehose-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}