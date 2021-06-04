locals {
  environment        = "preproduction"
  builder_account_id = "620540024451"
}

data "aws_caller_identity" "preproduction" {}

module "state_bucket" {
  source      = "../../module-template/remote-state-bucket"
  bucket_name = "cla-${local.environment}-state"
}

module "network" {
  source      = "../../components/networking"
  owner       = "platform"
  account_id  = data.aws_caller_identity.preproduction.account_id
  environment = local.environment
}

module "web_application_deployment" {
  source       = "../../components/codedeploy"
  role_arn     = aws_iam_role.codedeploy.arn
  service_name = aws_ecs_service.web_application.name
  cluster_arn  = aws_ecs_cluster.workloads.arn
}

data "aws_iam_policy_document" "infrastructure_pipeline_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.builder_account_id}:root"]
    }
  }
}
resource "aws_iam_role" "infrastructure_pipeline" {
  name = "infrastructure_pipeline"

  assume_role_policy = data.aws_iam_policy_document.infrastructure_pipeline_trust_policy.json
}

# intentionally more permissive so we can use IAM analyser/permission reduction tooling on it later on
resource "aws_iam_role_policy_attachment" "infrastructure_pipeline_admin_access" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.infrastructure_pipeline.name
}

resource "aws_ecs_cluster" "workloads" {
  name               = "workloads"
  capacity_providers = ["FARGATE"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "web_application" {
  name            = "web-application"
  cluster         = aws_ecs_cluster.workloads.id
  desired_count   = 3
  deployment_controller {
    type = "EXTERNAL"
  }
}

# resource "aws_ecs_task_definition" "web_application" {
#   family = "web-application"
#   container_definitions = jsonencode([
#   ])
# }

# the networking stuff needs to go here:
# speculating wildly
# - we need a task definition
#         which requires a container
#         we configure as vpc networking
#                   relates to-> a subnet/security group in a VPC
#
# we can then add the load balancer into that security group, and do other networking to expose it?
# so... because we need to connect to a load of external VPC networking we'll set that up first

resource "aws_security_group" "web_application_sg" {
  name        = "web_application_sg"
  description = "Allow http traffic for tin tulip scenario 1 web application"
  vpc_id      = module.network.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web_application" {
  name               = "web-application"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_application_sg.id]
  subnets            = module.network.private_subnets
}

resource "aws_lb_target_group" "web_application" {
  name        = "web-application"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id

  health_check {
    path    = "/"
    matcher = "302,200"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "web_application" {
  load_balancer_arn = aws_lb.web_application.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.web_application.arn
  default_action {
    target_group_arn = aws_lb_target_group.web_application.arn
    type             = "forward"
  }
}

# DNS stuff

locals {
  dns_first_level = "tintulip-scenario1.net"
  dns_second_level = "www.${local.dns_first_level}"
}

resource "aws_route53_zone" "tintulip_scenario1" {
  name = local.dns_first_level
}

resource "aws_route53_zone" "www_tintulip_scenario1" {
  name = local.dns_second_level
}

resource "aws_route53_record" "scenario1_zone_ns" {
  zone_id = aws_route53_zone.tintulip_scenario1.zone_id
  name    = local.dns_second_level
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.www_tintulip_scenario1.name_servers.0,
    aws_route53_zone.www_tintulip_scenario1.name_servers.1,
    aws_route53_zone.www_tintulip_scenario1.name_servers.2,
    aws_route53_zone.www_tintulip_scenario1.name_servers.3,
  ]
}

resource "aws_acm_certificate" "web_application" {
  domain_name       = local.dns_second_level
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "web_application_validation" {
  name    = aws_acm_certificate.web_application.domain_validation_options.resource_record_name
  type    = aws_acm_certificate.web_application.domain_validation_options.resource_record_type
  zone_id = aws_route53_zone.www_tintulip_scenario1.zone_id
  records = [aws_acm_certificate.web_application.domain_validation_options.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "web_application" {
  certificate_arn         = aws_acm_certificate.web_application.arn
  validation_record_fqdns = [aws_route53_record.web_application.fqdn]
}

resource "aws_route53_record" "web_application" {
  zone_id = aws_route53_zone.www_tintulip_scenario1.zone_id
  name    = local.dns_second_level
  type    = "A"

  alias {
    name                   = aws_lb.web_application.dns_name
    zone_id                = aws_lb.web_application.zone_id
    evaluate_target_health = true
  }
}