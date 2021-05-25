output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "role_arn" {
  value = aws_iam_role.role.arn
}

output "encrypted_key" {
  value = aws_iam_access_key.user_key.encrypted_secret
}
