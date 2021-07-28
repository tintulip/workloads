resource "aws_kms_key" "cloud_watch" {
  description             = "KMS key for cloudwatch log group"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloud_watch_logs.json
}


resource "aws_cloudwatch_log_group" "web_application" {

  name       = "web-application"
  kms_key_id = aws_kms_key.cloud_watch.arn

  retention_in_days = 30

  tags = {
    Environment = "preproduction"
    Application = "web-application"
  }
}

data "aws_iam_policy_document" "cloud_watch_logs" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.preproduction.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.eu-west-2.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.preproduction.account_id}:log-group:web-application"]
    }
  }

}

data "aws_iam_policy_document" "kms_key_policy" {

  statement {
    effect = "Allow"


    actions = [
      "kms:*"
    ]

    resources = [aws_iam_role.infrastructure_pipeline.arn]
  }
}