locals {
  environment        = "preproduction"
  builder_account_id = "620540024451"
  service_name       = "web-application"
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

# service stuff
resource "aws_ecs_cluster" "workloads" {
  name               = "workloads"
  capacity_providers = ["FARGATE"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "web_application" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.workloads.id
  task_definition = aws_ecs_task_definition.web_application.arn
  desired_count   = 3
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web_application.0.arn
    container_name   = "web-application"
    container_port   = 8080
  }
}



resource "aws_ecs_task_definition" "web_application" {
  family = "web-application"
  container_definitions = jsonencode([
    {
      name      = "web-application"
      image     = "${data.aws_caller_identity.preproduction.account_id}.dkr.ecr.eu-west-2.amazonaws.com/web-application:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 80
        }
      ]
    }
  ])
}

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

locals {
  target_groups = [
    "green",
    "blue",
  ]
}

resource "aws_lb_target_group" "web_application" {
  count       = length(local.target_groups)
  name        = "web-application-tg-${element(local.target_groups, count.index)}"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
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
    target_group_arn = aws_lb_target_group.web_application.0.arn
    type             = "forward"
  }
}

# DNS stuff

locals {
  dns_domain               = "tintulip-scenario1.net"
  web_application_hostname = "www.${local.dns_domain}"
}

resource "aws_route53_zone" "tintulip_scenario1" {
  name = local.dns_domain
}

resource "aws_acm_certificate" "web_application" {
  domain_name       = local.web_application_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "web_application_validation" {
  for_each = {
    for dvo in aws_acm_certificate.web_application.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  zone_id = aws_route53_zone.tintulip_scenario1.zone_id
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "web_application" {
  certificate_arn         = aws_acm_certificate.web_application.arn
  validation_record_fqdns = [for record in aws_route53_record.web_application_validation : record.fqdn]
}

resource "aws_route53_record" "web_application" {
  zone_id = aws_route53_zone.tintulip_scenario1.zone_id
  name    = local.web_application_hostname
  type    = "A"

  alias {
    name                   = aws_lb.web_application.dns_name
    zone_id                = aws_lb.web_application.zone_id
    evaluate_target_health = true
  }
}