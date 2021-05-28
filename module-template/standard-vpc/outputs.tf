output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.workload.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.workload.arn
}

output "private_subnets" {
  description = "Private subnets of VPC"
  value       = var.private_subnets
}

output "cidr" {
  description = "Cidr of VPC"
  value       = var.cidr
}