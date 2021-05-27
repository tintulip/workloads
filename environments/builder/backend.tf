terraform {
  backend "s3" {
    bucket = "cla-builder-state"
    key    = "pipeline-factory/infra-pipeline.tfstate"
    region = "eu-west-2"
  }
}