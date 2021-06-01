output "application_infra_webhook" {
  value = aws_codepipeline_webhook.application_infra.url
}
