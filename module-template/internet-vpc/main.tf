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

  enable_nat_gateway = true
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

resource "aws_lb" "internet" {
  name                             = "${var.vpc_name}-lb"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = module.vpc.private_subnets

  enable_deletion_protection = true

  tags = {
    Environment = var.env
  }
}

resource "aws_vpc_endpoint_service" "internet" {
  count                      = var.create_endpoint ? 1 : 0
  acceptance_required        = var.acceptance_required
  allowed_principals         = var.allowed_principals
  network_load_balancer_arns = [aws_lb.internet.arn]
}