module "tgw" {
  source = "terraform-aws-modules/transit-gateway/aws"

  name            = var.tgw_name
  description     = "${var.tgw_name} in ${var.environment} owned by ${var.owner}"

  enable_auto_accept_shared_attachments = true # When "true" there is no need for RAM resources if using multiple AWS accounts

  vpc_attachments = {
    vpc1 = {
      vpc_id                                          = module.internet_vpc.vpc_id
      subnet_ids                                      = module.internet_vpc.private_subnets
      dns_support                                     = true
      ipv6_support                                    = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false

      tgw_routes = [
        {
          destination_cidr_block = "30.0.0.0/16"
        },
        {
          blackhole              = true
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    },
    vpc2 = {
      vpc_id     = module.endpoint_vpc.vpc_id
      subnet_ids = module.endpoint_vpc.private_subnets

      tgw_routes = [
        {
          destination_cidr_block = "50.0.0.0/16"
        },
        {
          blackhole              = true
          destination_cidr_block = "10.10.10.10/32"
        }
      ]
    },
  }

  ram_allow_external_principals = true
  ram_principals                = [307990089504]

  tags = {
    Purpose = "tgw-complete-example"
  }
}

module "internet_vpc" {
  source = "../internet-vpc"
  env = var.environment
  owner = var.owner
  allowed_principals = ["arn:aws:iam::${var.account_id}:root"]
  account_id = var.account_id
  environment = var.environment
}

module "endpoint_vpc" {
  source = "../endpoint-vpc"
  env = var.environment
  owner = var.owner
  allowed_principals = ["arn:aws:iam::${var.account_id}:root"]
  account_id = var.account_id
  environment = var.environment
}