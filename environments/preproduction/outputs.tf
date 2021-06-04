output "infra_pipeline_role_arn" {
  value = aws_iam_role.infrastructure_pipeline.arn
}

output "web_application_url" {
  value = aws_lb.web_application.dns_name
}
