locals {
  environment = "builder"
}

module "state_bucket" {
  source      = "../../module-template/remote-state-bucket"
  bucket_name = "cla-${local.environment}-state"
}

module "internet_vpc" {
  source = "../../module-template/internet-vpc"
  env = local.environment
  owner = "Governance"
}