data "aws_iam_policy_document" "assume_by_codedeploy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.builder_account_id}:root"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "app_deployer"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codedeploy.json
}

data "aws_iam_policy_document" "codedeploy" {

  #checkov:skip=CKV_AWS_111: FIXME this being broad is intentional for now. #85 raised to follow up.

  statement {
    sid    = "AllowLoadBalancingAndECSModifications"
    effect = "Allow"

    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = ["s3:GetObject"]

    resources = ["arn:aws:s3:::cla-pipeline-artifacts/*"]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = [
      aws_iam_role.execution_role.arn,
      aws_iam_role.task_role.arn
    ]
  }

  statement {
    sid    = "AllowECS"
    effect = "Allow"

    actions = ["ecs:*"]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codedeploy" {
  role   = aws_iam_role.codedeploy.name
  policy = data.aws_iam_policy_document.codedeploy.json
}

data "aws_iam_policy_document" "execution_role" {

  #checkov:skip=CKV_AWS_111: FIXME this might be locked down to a specific repo - we have the id. #85 raised to follow up.

  statement {
    sid    = "AllowECRPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]

    resources = [
      "arn:aws:secretsmanager:eu-west-2:961889248176:secret:db_password*",
      aws_kms_key.rds_secret.arn
    ]
  }
}

data "aws_iam_policy_document" "task_role" {

  #checkov:skip=CKV_AWS_111: FIXME look into this - can we even be specific in this case?. #85 raised to follow up.

  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters"]

    resources = [aws_ecs_cluster.workloads.arn]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]

    resources = [
      aws_secretsmanager_secret.db_password.arn,
      aws_kms_key.rds_secret.arn
    ]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${local.service_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_ecs.json
}

resource "aws_iam_role_policy" "execution_role" {
  role   = aws_iam_role.execution_role.name
  policy = data.aws_iam_policy_document.execution_role.json
}

resource "aws_iam_role" "task_role" {
  name               = "${local.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_ecs.json
}

resource "aws_iam_role_policy" "task_role" {
  role   = aws_iam_role.task_role.name
  policy = data.aws_iam_policy_document.task_role.json
}

data "aws_iam_policy_document" "assume_by_ecs" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}