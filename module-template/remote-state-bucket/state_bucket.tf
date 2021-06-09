resource "aws_s3_bucket" "state_bucket" {
  #checkov:skip=CKV_AWS_144:Not required to have cross region enabled
  #checkov:skip=CKV_AWS_52:Cannot enable mfa_delete when applying with SSO
  # skip access logging
  #tfsec:ignore:AWS002
  #checkov:skip=CKV_AWS_18:currently cannot send access logs anywhere
  bucket        = var.bucket_name
  force_destroy = "true"


  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled    = "true"
    mfa_delete = "false"
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}