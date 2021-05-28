//module "tgw" {
//  source = "terraform-aws-modules/transit-gateway/aws"
//
//  name        = var.tgw_name
//  description = "${var.tgw_name} in ${var.environment} owned by ${var.owner}"
//
//  enable_auto_accept_shared_attachments = true # When "true" there is no need for RAM resources if using multiple AWS accounts
//
//  vpc_attachments = {
//    vpc1 = {
//      vpc_id                                          = module.workload.vpc_id
//      subnet_ids                                      = module.workload.private_subnets
//      dns_support                                     = true
//      ipv6_support                                    = true
//      transit_gateway_default_route_table_association = false
//      transit_gateway_default_route_table_propagation = false
//
//      tgw_routes = [
//        {
//          destination_cidr_block = var.workload_cidr
//        }
//      ]
//    },
//    vpc2 = {
//      vpc_id     = module.endpoint_vpc.vpc_id
//      subnet_ids = module.endpoint_vpc.private_subnets
//
//      tgw_routes = [
//        {
//          destination_cidr_block = module.endpoint_vpc.cidr
//        }
//      ]
//    },
//  }
//
//  ram_allow_external_principals = true
//  ram_principals                = [var.account_id]
//
//  tags = {
//    Purpose = var.tgw_name
//  }
//}
//module "endpoint_vpc" {
//  source = "../endpoint-vpc"
//  env    = var.environment
//  owner  = var.owner
//}


module "internet_vpc" {
  source             = "../../module-template/internet-vpc"
  env                = var.environment
  owner              = var.owner
  allowed_principals = ["arn:aws:iam::${var.account_id}:root"]
}

module "workload_vpc" {
  source      = "../../module-template/standard-vpc"
  account_id  = var.account_id
  environment = var.environment
  name        = var.workload_vpc_name
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.workload_vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint" "code_pipeline" {
  vpc_id            = module.workload_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.codepipeline"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.allow_ingress_from_workload_vpc.id,
  ]
}

resource "aws_vpc_endpoint" "internet" {
  vpc_id            = module.workload_vpc.vpc_id
  service_name      = module.internet_vpc.internet_vpc_endpoint_service_name
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.allow_ingress_from_workload_vpc.id,
  ]
}
