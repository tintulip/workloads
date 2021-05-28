provider "aws" {
  region = local.region
}

locals {
  region = "eu-west-2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr

  azs             = local.az
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_ipv6 = true

  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = {
    Name = "overridden-name-public"
  }

  tags = {
    Owner       = var.owner
    Environment = var.env
  }

  vpc_tags = {
    Name = var.vpc_name
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint" "code_pipeline" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.codepipeline"
}
