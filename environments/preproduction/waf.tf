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

  rule {
    name     = "common-rule-set"
    priority = 1

    action {
      block {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
  }

  rule {
    name     = "known-bad-inputs"
    priority = 2

    action {
      block {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
  }

  rule {
    name     = "sql-database"
    priority = 3

    action {
      block {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
  }

  rule {
    name     = "linux-rule-set"
    priority = 4

    action {
      block {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }
  }

  rule {
    name     = "unix-rule-set"
    priority = 5

    action {
      block {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-web-application"
    sampled_requests_enabled   = true
  }
}