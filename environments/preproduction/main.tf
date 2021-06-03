locals {
  environment = "preproduction"
  builder_account_id = "620540024451"
}

data "aws_caller_identity" "preproduction" {}

module "state_bucket" {
  source      = "../../module-template/remote-state-bucket"
  bucket_name = "cla-${local.environment}-state"
}

module "network" {
  source      = "../../components/networking"
  owner       = "platform"
  account_id  = data.aws_caller_identity.preproduction.account_id
  environment = local.environment
}

data "aws_iam_policy_document" "infrastructure_pipeline_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.builder_account_id}:root"]
    }
  }
}
resource "aws_iam_role" "infrastructure_pipeline" {
  name = "infrastructure_pipeline"

  assume_role_policy = data.aws_iam_policy_document.infrastructure_pipeline_trust_policy.json
}

# intentionally more permissive so we can use IAM analyser/permission reduction tooling on it later on
resource "aws_iam_role_policy_attachment" "infrastructure_pipeline_admin_access" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.infrastructure_pipeline.name
}
