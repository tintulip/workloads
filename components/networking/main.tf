module "workload_vpc" {
  source = "../../module-template/vpc"

  vpc_name   = "workloads"
  aws_region = "eu-west-2"
  cidr_block = "10.100.0.0/16"

  public_subnets  = ["10.100.0.0/24", "10.100.1.0/24", "10.100.2.0/24"]
  private_subnets = ["10.100.10.0/24", "10.100.11.0/24", "10.100.12.0/24"]

  environment = var.environment
  owner       = var.owner
}
