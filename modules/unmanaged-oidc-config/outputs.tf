output "secret_arn" {
  value = module.aws_secrets_manager.secret_arn
}

output "issuer_url" {
  value = rhcs_rosa_oidc_config_input.oidc_input.issuer_url
}
