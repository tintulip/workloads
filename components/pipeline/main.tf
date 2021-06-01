resource "aws_codepipeline" "application_infra" {
  name     = "application-infra-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.provider.arn
        FullRepositoryId = "tintulip/application-infra"
        BranchName       = "main"
        DetectChanges    = false
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      configuration = {
        ProjectName = aws_codebuild_project.apply_terraform.name
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "cla-pipeline-artifacts"
  acl    = "private"
}
resource "random_password" "webhooks_secret" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "aws_codepipeline_webhook" "application_infra" {
  name            = "application-infra-webhook"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.application_infra.name

  authentication_configuration {
    secret_token = aws_ssm_parameter.webhook_secret.value
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

resource "aws_ssm_parameter" "webhook_secret" {
  name        = "/repository/application-infra/webhook-secret"
  description = "The secret for the webhook"
  type        = "SecureString"
  value       = random_password.webhooks_secret.result

  tags = {
    environment = "builder"
  }
}