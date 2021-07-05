resource "aws_wafv2_web_acl_logging_configuration" "waf_logging_config" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_delivery_stream.arn]
  resource_arn            = aws_wafv2_web_acl.waf.arn
}

resource "aws_kinesis_firehose_delivery_stream" "waf_delivery_stream" {
  name        = "aws-waf-logs-firehose-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.waf_bucket.arn
    compression_format = "GZIP"
    kms_key_arn        = data.aws_kms_alias.s3.target_key_arn
  }
}

data "aws_kms_alias" "s3" {
  name = "alias/aws/s3"
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

data "aws_iam_policy_document" "waf_logs" {
  statement {
    actions   = ["s3:PutReplicationConfiguration"]
    resources = [aws_s3_bucket.waf_bucket.arn]
    principals {
      identifiers = [aws_iam_role.log_replication.arn]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "waf_logs" {
  bucket = aws_s3_bucket.waf_bucket.id
  policy = data.aws_iam_policy_document.waf_logs.json
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

resource "aws_iam_role_policy" "custom-policy" {
  name   = "waf-firehose-role-policy"
  role   = aws_iam_role.firehose_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.waf_bucket.arn}",
        "${aws_s3_bucket.waf_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/wafv2.amazonaws.com/AWSServiceRoleForWAFV2Logging"
    }
  ]
}
EOF
}