terraform {
  backend "s3" {
    bucket       = "tfstate-961889248176-preproduction"
    key          = "pipeline-factory/preproduction.tfstate"
    region       = "eu-west-2"
    sts_endpoint = "https://sts.eu-west-2.amazonaws.com"
    role_arn     = "arn:aws:iam::961889248176:role/infrastructure_pipeline"
  }
}

locals {
  tags = {
    "tf:stack" = "workloads:preproduction"
  }
}

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = local.tags
  }
  assume_role {
    role_arn = "arn:aws:iam::961889248176:role/infrastructure_pipeline"
  }
}