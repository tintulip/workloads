locals {
  environment = "builder"
}

data "aws_caller_identity" "builder" {}

module "state_bucket" {
  source      = "../../module-template/remote-state-bucket"
  bucket_name = "cla-${local.environment}-state"
}

module "network" {
  source      = "../../components/networking"
  owner       = "governance"
  account_id  = data.aws_caller_identity.builder.account_id
  environment = local.environment
}