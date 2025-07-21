output "role_name" {
  description = "VPCE Role name"
  value       = time_sleep.vpce_role_propagation.triggers["role_name"]
}

output "role_arn" {
  description = "VPCE Role ARN"
  value       = time_sleep.vpce_role_propagation.triggers["role_arn"]
}

output "policy_arn" {
  description = "VPCE Policy ARN"
  value       = time_sleep.vpce_role_propagation.triggers["policy_arn"]
}
