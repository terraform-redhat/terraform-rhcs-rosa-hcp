output "account_role_prefix" {
  value = local.account_role_prefix_valid
}

output "openshift_version" {
  value = var.openshift_version
}

output "account_roles_arn" {
  value = { for idx, value in module.hcp_account_iam_role : local.account_roles_properties[idx].role_name => value.iam_role_arn }
}

output "path" {
  value = var.path
}
