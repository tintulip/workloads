locals {
  environment = "builder"
}

data "aws_caller_identity" "builder" {}

module "state_bucket" {
  source      = "../../module-template/remote-state-bucket"
  bucket_name = "cla-${local.environment}-state"
}

module "standard-environment" {
  source = "../../module-template/standard-environment"
  owner = "Governance"
  allowed_principals = ["arn:aws:iam::${data.aws_caller_identity.builder.account_id}:root"]
  account_id = data.aws_caller_identity.builder.account_id
  environment = local.environment
  tgw_name = "tgw-endpoint-${local.environment}"
}