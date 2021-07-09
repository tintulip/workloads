data "aws_caller_identity" "preproduction" {}

locals {
  environment             = "preproduction"
  builder_account_id      = "620540024451"
  service_name            = "web-application"
  access_logs_prefix      = "web_application_lb"
  access_logs_waf_prefix  = "web_application_lb_waf"
  access_logs_bucket_name = "access-logs-${data.aws_caller_identity.preproduction.account_id}"
}

module "kms_bucket" {
  source      = "../../module-template/kms-state-bucket"
  bucket_name = "preproduction"
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

resource "aws_iam_role_policy" "state_bucket_access" {
  policy = module.kms_bucket.policy_document
  role   = aws_iam_role.infrastructure_pipeline.name
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
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.network.private_subnets
    security_groups = [aws_security_group.web_application_service_sg.id]
  }
  deployment_controller {
    type = "ECS"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web_application.arn
    container_name   = "web-application"
    container_port   = 8080
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.waf.arn
    container_name   = "web-application"
    container_port   = 8080
  }
}



resource "aws_ecs_task_definition" "web_application" {
  family                   = "web-application"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512  # 0.5vCPU
  memory                   = 1024 # in MiB
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "web-application"
      image     = "${data.aws_caller_identity.preproduction.account_id}.dkr.ecr.eu-west-2.amazonaws.com/web-application"
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://${aws_db_instance.web_application_db.endpoint}/${aws_db_instance.web_application_db.name}"
        },
        {
          name  = "SPRING_DATASOURCE_USERNAME"
          value = aws_db_instance.web_application_db.username
        },
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn

        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "eu-west-2"
          awslogs-group         = "web-application"
          awslogs-stream-prefix = "workloads"
        }
      }
    }
  ])
}


resource "aws_cloudwatch_log_group" "web_application" {

  #checkov:skip=CKV_AWS_158: FIXME no kms on this for now. #86 to follow up

  name = "web-application"

  retention_in_days = 30

  tags = {
    Environment = "preproduction"
    Application = "web-application"
  }
}

resource "aws_security_group_rule" "allow_lb_service" {
  description              = "Allow traffic from the loadabalancer to the web-application"
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_application_lb_sg.id
  source_security_group_id = aws_security_group.web_application_service_sg.id
}

resource "aws_security_group_rule" "allow_lb_ingress" {
  description       = "Allow traffic from the internet to the loadbalancer"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.web_application_lb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

#tfsec:ignore:AWS008
resource "aws_security_group" "web_application_lb_sg" {
  name        = "web_application_lb_sg"
  description = "Allow http traffic for tin tulip scenario 1 web application on the load balancer"
  vpc_id      = module.network.vpc_id
}

resource "aws_security_group_rule" "allow_service_database" {
  description              = "Allow traffic from the web-application to the database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_application_service_sg.id
  source_security_group_id = aws_security_group.web_application_database_sg.id
}

resource "aws_security_group_rule" "allow_service_lb" {
  description              = "Allow traffic to the web-application from the loadbalancer"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_application_service_sg.id
  source_security_group_id = aws_security_group.web_application_lb_sg.id
}

resource "aws_security_group_rule" "allow_service_to_vpc_endpoints" {
  description              = "Allow traffic from the web-application to the VPC endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_application_service_sg.id
  source_security_group_id = aws_security_group.services_to_vpc_endpoints.id
}

resource "aws_security_group_rule" "allow_service_https_to_s3" {
  description       = "Allow traffic from the web-application to the S3 endpoint"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.web_application_service_sg.id
  prefix_list_ids   = [data.aws_prefix_list.private_s3.id]
}

resource "aws_security_group" "web_application_service_sg" {
  name        = "web_application_service_sg"
  description = "Allow http traffic for tin tulip scenario 1 web application service"
  vpc_id      = module.network.vpc_id
}

#tfsec:ignore:AWS005
resource "aws_lb" "web_application" {
  name               = "web-application"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_application_lb_sg.id]
  subnets            = module.network.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = local.access_logs_prefix
    enabled = true
  }
}

resource "aws_lb_target_group" "web_application" {
  name        = "web-application-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id

  health_check {
    path    = "/actuator/health"
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
  dns_domain               = "tintulip-scenario1.net"
  web_application_hostname = "www.${local.dns_domain}"
  waf_application_hostname = "waf.${local.dns_domain}"
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

resource "aws_s3_bucket" "access_logs" {
  #checkov:skip=CKV_AWS_52:Bucket is created by a pipeline
  #checkov:skip=CKV_AWS_18:Access logging needs to go into a cross account bucket
  #checkov:skip=CKV_AWS_144:Not required to have cross region enabled
  #checkov:skip=CKV_AWS_145:Cannot use KMS for cross-account log replication
  bucket = local.access_logs_bucket_name
  acl    = "private"
  policy = data.aws_iam_policy_document.access_logs.json

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "log-expire"
    enabled = true

    tags = {
      rule      = "log-expire"
      autoclean = "true"
    }

    expiration {
      days = 30
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_elb_service_account" "elb" {}

data "aws_iam_policy_document" "access_logs" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.elb.arn]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.access_logs_bucket_name}/${local.access_logs_prefix}/AWSLogs/*",
      "arn:aws:s3:::${local.access_logs_bucket_name}/${local.access_logs_waf_prefix}/AWSLogs/*",
    ]
  }
}


## Scenario 3 - Create user within the Builder account with AdministratorAccess policy and output keys

# 1. Create "attacker" user
resource "aws_iam_user" "attacker" {
  name = "attacker"
  path = "/system/"
}

# 2. Generate and output keys
resource "aws_iam_access_key" "attacker" {
  user = aws_iam_user.attacker.name
}

output "attacker_access_key_id" {
  value = aws_iam_access_key.attacker.id
}

output "attacker_access_key_secret" {
  value = aws_iam_access_key.attacker.secret
}

# 3. Attach AdministratorAccess policy to attacker
resource "aws_iam_user_policy_attachment" "attacker-attach" {
  user       = aws_iam_user.attacker.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

