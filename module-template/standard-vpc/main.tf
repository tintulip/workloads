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

locals {
  az = { 0 : "${var.region}a"
    1 : "${var.region}b"
    2 : "${var.region}c"
  }
}