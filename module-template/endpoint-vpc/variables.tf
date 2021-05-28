variable "vpc_name" {
  default = "internet"
}

variable "cidr" {
  default = "172.63.0.0/16"
}

variable "private_subnets" {
  default = ["172.63.1.0/24", "172.63.2.0/24", "172.63.3.0/24"]
}

variable "public_subnets" {
  default = ["172.63.101.0/24", "172.63.102.0/24", "172.63.103.0/24"]
}

variable "region" {
  default = "eu-west-2"
}

variable "env" {
}


variable "owner" {
}

locals {
  az = ["${var.region}a", "${var.region}b", "${var.region}c"]
}