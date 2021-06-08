output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.workload_vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.workload_vpc.vpc_arn
}

output "private_subnets" {
  description = "Private subnets of VPC"
  value       = module.workload_vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnets of VPC"
  value       = module.workload_vpc.public_subnets
}