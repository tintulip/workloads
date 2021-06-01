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

  tags = {
    Owner       = var.owner
    Environment = var.environment
  }

  vpc_tags = {
    Name = var.vpc_name
  }
}