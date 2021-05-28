variable "vpc_name" {
  default = "internet"
}

variable "cidr" {
  default = "172.16.0.0/16"
}

variable "private_subnets" {
  default = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "public_subnets" {
  default = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
}

variable "region" {
  default = "eu-west-2"
}

variable "env" {
}

variable "owner" {
}

variable "create_endpoint" {
  default = true
}

variable "acceptance_required" {
  default = true
}

variable "allowed_principals" {
}

locals {
  az = ["${var.region}a", "${var.region}b", "${var.region}c"]
}