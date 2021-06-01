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