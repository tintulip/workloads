variable "vpc_name" {
}

variable "cidr_block" {
  default = "172.16.0.0/16"
}

variable "private_subnets" {
  default = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "public_subnets" {
  default = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
}

variable "aws_region" {
  default = "eu-west-2"
}

variable "environment" {
  description = "for tagging"
}

variable "owner" {
  description = "for tagging"
}
