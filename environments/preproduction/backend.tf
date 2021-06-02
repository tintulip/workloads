terraform {
  backend "s3" {
    bucket = "cla-preproduction-state"
    key    = "pipeline-factory/preproduction.tfstate"
    region = "eu-west-2"
  }
}