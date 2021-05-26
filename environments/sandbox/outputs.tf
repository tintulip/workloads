output "encrypted_github_actions_secret_key" {
  value = module.sandbox_iam.encrypted_secret_key
}

output "github_actions_access_key" {
  value = module.sandbox_iam.access_key
}