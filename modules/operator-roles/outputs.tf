output "operator_role_prefix" {
  value       = time_sleep.role_resources_propagation.triggers["operator_role_prefix"]
  description = "Prefix used for generated AWS operator policies."
}

output "operator_roles_arn" {
  value       = jsondecode(time_sleep.role_resources_propagation.triggers["operator_role_arns"])
  description = "List of Amazon Resource Names (ARNs) for all operator roles created."
}

output "shared_vpc_policy_attachments" {
  value       = jsondecode(time_sleep.role_resources_propagation.triggers["shared_vpc_policy_attachments"])
  description = "A list of Amazon Resource Names (ARNs) related to the shared VPC"
}
