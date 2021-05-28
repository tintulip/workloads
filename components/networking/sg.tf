resource "aws_security_group" "allow_ingress_from_workload_vpc" {
  name        = "allow_ingress_from_workload"
  description = "Allow endpoint inbound traffic"
  vpc_id      = module.workload_vpc.vpc_id

  ingress {
    description = "Ingress from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.workload_vpc.cidr]
  }

  tags = {
    Name = "workload_ingress"
  }
}