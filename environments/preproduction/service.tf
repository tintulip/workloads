resource "aws_ecr_repository" "web_application" {
  #checkov:skip=CKV_AWS_136: no kms for now - #86 to follow up
  #tfsec:ignore:AWS093: no kms for now - #86 to follow up
  name                 = local.service_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "allow_builder_to_push" {
  repository = aws_ecr_repository.web_application.name
  policy     = data.aws_iam_policy_document.builder_push.json
}

data "aws_iam_policy_document" "builder_push" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeRepositories",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.builder_account_id}:root"]
    }
  }
}