variable "environment" {
}

variable "account_id" {
}

variable "name" {
}

variable "region" {
  default = "eu-west-2"
}

variable "cidr" {
  default = "172.24.0.0/16"
}

variable "private_subnets" {
  default = ["172.24.1.0/24", "172.24.2.0/24", "172.24.3.0/24"]
}