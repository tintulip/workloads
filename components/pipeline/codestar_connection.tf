resource "aws_codestarconnections_connection" "provider" {
  name          = "tintulip-connection"
  provider_type = "GitHub"
}