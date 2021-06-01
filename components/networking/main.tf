module "internet_vpc" {
  source = "../../module-template/internet-vpc"

  vpc_name   = "builder-pipeline"
  aws_region = "eu-west-2"
  cidr_block = "10.100.0.0/16"

  public_subnets  = ["10.100.0.0/24", "10.100.1.0/24", "10.100.2.0/24"]
  private_subnets = ["10.100.10.0/24", "10.100.11.0/24", "10.100.12.0/24"]

  environment        = var.environment
  owner              = var.owner
  allowed_principals = ["arn:aws:iam::${var.account_id}:root"]
}
