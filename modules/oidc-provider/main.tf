resource "time_sleep" "wait_10_seconds" {
  create_duration  = "10s"
  destroy_duration = "30s"
}

resource "rhcs_rosa_oidc_config" "oidc_config" {
  // TODO nargaman failes on first time, need to have retries in rosa_oidc_config_resource code?
  depends_on = [time_sleep.wait_10_seconds]

  managed            = var.managed
  secret_arn         = var.secret_arn
  issuer_url         = var.issuer_url
  installer_role_arn = var.installer_role_arn
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url = "https://${rhcs_rosa_oidc_config.oidc_config.oidc_endpoint_url}"

  client_id_list = [
    "openshift",
    "sts.amazonaws.com"
  ]

  tags = merge(var.tags, {
    red-hat-managed = true
  })

  thumbprint_list = [rhcs_rosa_oidc_config.oidc_config.thumbprint]
}
