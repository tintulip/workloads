#tfsec:ignore:AWS005
resource "aws_lb" "waf" {
  name               = "web-application-waf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_application_lb_sg.id]
  subnets            = module.network.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = local.access_logs_waf_prefix
    enabled = true
  }
}

resource "aws_lb_target_group" "waf" {
  name        = "web-app-waf-tg"
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


resource "aws_lb_listener" "waf" {
  load_balancer_arn = aws_lb.waf.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.waf_cert.arn
  default_action {
    target_group_arn = aws_lb_target_group.waf.arn
    type             = "forward"
  }
}

resource "aws_acm_certificate" "waf_cert" {
  domain_name       = local.waf_application_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "waf_validation" {
  for_each = {
    for dvo in aws_acm_certificate.waf_cert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "waf_validation" {
  certificate_arn         = aws_acm_certificate.waf_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.waf_validation : record.fqdn]
}

resource "aws_route53_record" "waf_record" {
  zone_id = aws_route53_zone.tintulip_scenario1.zone_id
  name    = local.waf_application_hostname
  type    = "A"

  alias {
    name                   = aws_lb.waf.dns_name
    zone_id                = aws_lb.waf.zone_id
    evaluate_target_health = true
  }
}


# S4 - Load balancer content injection
resource "aws_lb_listener_rule" "addUser" {
  listener_arn = aws_lb_listener.waf.arn

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = file("${path.module}/addUser.html")
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/addUser"]
    }
  }
}
