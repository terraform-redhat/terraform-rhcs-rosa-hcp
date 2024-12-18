output "role_name" {
  description = "Route53 Role name"
  value       = time_sleep.route53_role_propagation.triggers["role_name"]
}

output "role_arn" {
  description = "Route53 Role ARN"
  value       = time_sleep.route53_role_propagation.triggers["role_arn"]
}

output "policy_arn" {
  description = "Route53 Policy ARN"
  value       = time_sleep.route53_role_propagation.triggers["policy_arn"]
}
