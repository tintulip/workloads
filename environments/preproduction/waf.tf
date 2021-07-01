resource "aws_wafv2_web_acl_association" "waf" {
  resource_arn = aws_lb.waf.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}

resource "aws_wafv2_web_acl" "waf" {
  name  = "waf-web-application"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-web-application"
    sampled_requests_enabled   = true
  }
}