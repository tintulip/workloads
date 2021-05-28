locals {
  environment = "builder"
}

data "aws_caller_identity" "builder" {}

module "state_bucket" {
  source      = "../../module-template/remote-state-bucket"
  bucket_name = "cla-${local.environment}-state"
}

module "standard_environment" {
  source            = "../../module-template/standard-environment"
  owner             = "Governance"
  account_id        = data.aws_caller_identity.builder.account_id
  environment       = local.environment
  tgw_name          = "tgw-endpoint-${local.environment}"
  workload_vpc_name = "code-pipeline"

  providers = {
    aws = aws
  }
}