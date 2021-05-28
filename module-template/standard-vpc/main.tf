resource "aws_vpc" "workload" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "private" {
  for_each          = local.az
  vpc_id            = aws_vpc.workload.id
  cidr_block        = var.private_subnets[each.key]
  availability_zone = each.value
}

# For TESTING only
//resource "aws_subnet" "public" {
//  for_each          = local.az
//  vpc_id            = aws_vpc.workload.id
//  cidr_block        = local.public_subnets[each.key]
//  availability_zone = each.value
//}

locals {
  az = { 0 : "${var.region}a"
    1 : "${var.region}b"
    2 : "${var.region}c"
  }

  #public_subnets = ["172.24.101.0/24", "172.24.102.0/24", "172.24.103.0/24"]
}