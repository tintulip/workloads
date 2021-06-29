locals {
  az = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr_block

  azs             = local.az
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "${var.vpc_name}-public"
  }

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Owner       = var.owner
    Environment = var.environment
  }

  vpc_tags = {
    Name = var.vpc_name
  }
}