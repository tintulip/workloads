output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "private_subnets" {
  description = "Private subnets of VPC"
  value       = module.vpc.private_subnets
}

output "internet_vpc_endpoint_service_name" {
  description = "Service endpoint service name of VPC"
  value       = aws_vpc_endpoint_service.internet[0].service_name
}