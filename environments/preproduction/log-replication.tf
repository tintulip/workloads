resource "aws_iam_role" "log_replication" {
  name = "log-replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}

resource "aws_iam_role_policy" "log_replication" {
  policy = data.aws_iam_policy_document.log_replication.json
  role   = aws_iam_role.log_replication.id
}

data "aws_iam_policy_document" "log_replication" {
  #checkov:skip=CKV_AWS_111:Allow KMS decrypt/encrypt on any resource
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:PutReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.waf_bucket.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      "${aws_s3_bucket.waf_bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = [
      "arn:aws:s3:::cla-preprod-app-logs/*"
    ]
  }

  # statement {
  #   actions = [
  #     "kms:Decrypt"
  #   ]

  #   condition {
  #     test     = "StringLike"
  #     variable = "kms:ViaService"
  #     values   = ["s3.eu-west-2.amazonaws.com"]
  #   }

  #   resources = [
  #     local.log_rep_kms_key
  #   ]
  # }

  # statement {
  #   actions = [
  #     "kms:Decrypt"
  #   ]
  #   resources = [
  #     data.aws_kms_key.s3.arn
  #   ]
  # }

  # statement {
  #   actions = [
  #     "kms:Encrypt"
  #   ]

  #   condition {
  #     test     = "StringLike"
  #     variable = "kms:ViaService"
  #     values   = ["s3.eu-west-2.amazonaws.com"]
  #   }

  #   resources = [
  #     local.log_rep_kms_key
  #   ]
  # }
}
