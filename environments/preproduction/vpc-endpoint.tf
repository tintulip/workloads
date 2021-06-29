data "aws_vpc_endpoint_service" "secretsmanager" {
  service = "secretsmanager"
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = module.network.vpc_id
  service_name      = data.aws_vpc_endpoint_service.secretsmanager.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.services_to_secretsmanager.id]
  subnet_ids         = module.network.private_subnets

  private_dns_enabled = true
}

resource "aws_security_group_rule" "allow_secretsmanager_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.services_to_secretsmanager.id
  source_security_group_id = aws_security_group.web_application_service_sg.id
}

resource "aws_security_group" "services_to_secretsmanager" {
  name        = "services_to_secretsmanager"
  description = "Allow ingress traffic to secretsmanager"
  vpc_id      = module.network.vpc_id
}