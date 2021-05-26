terraform {
  backend "s3" {
    bucket = "cla-sandbox-state"
    key    = "pipeline-factory/infra-pipeline.tfstate"
    region = "eu-west-2"
  }
}