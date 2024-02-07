output "operator_role_prefix" {
  value = local.operator_role_prefix_valid
}

output "operator_roles_arn" {
  value = { for idx, value in module.hcp_operator_iam_role : local.operator_roles_properties[idx].role_name => value.iam_role_arn }
}