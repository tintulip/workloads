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

data "aws_iam_policy_document" "kms_for_infra_role" {

  statement {
    effect = "Allow"


    actions = [
      "kms:*"
    ]

    resources = [aws_kms_key.cloud_watch.arn]
  }
}

resource "aws_iam_policy" "kms_key_for_cloud_watch_logs" {
  name   = "kms_key_for_cloud_watch_logs"
  policy = data.aws_iam_policy_document.kms_for_infra_role.json
}

resource "aws_iam_role_policy_attachment" "infra_role_kms_access" {
  role       = aws_iam_role.infrastructure_pipeline.name
  policy_arn = aws_iam_policy.kms_key_for_cloud_watch_logs.arn
}