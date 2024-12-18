output "route53_role_name" {
  description = "Route53 Role name"
  value       = time_sleep.shared_resources_propagation.triggers["route53_role_name"]
}

output "route53_role_arn" {
  description = "Route53 Role ARN"
  value       = time_sleep.shared_resources_propagation.triggers["route53_role_arn"]
}

output "vpce_role_name" {
  description = "VPCE Role name"
  value       = time_sleep.shared_resources_propagation.triggers["vpce_role_name"]
}

output "vpce_role_arn" {
  description = "VPCE Role ARN"
  value       = time_sleep.shared_resources_propagation.triggers["vpce_role_arn"]
}

output "ingress_private_hosted_zone_arn" {
  description = "Ingress Private Hosted Zone ARN"
  value       = time_sleep.shared_resources_propagation.triggers["ingress_private_hosted_zone_arn"]
}

output "hcp_internal_communication_private_hosted_zone_arn" {
  description = "HCP Internal Communication Private Hosted Zone ARN"
  value       = time_sleep.shared_resources_propagation.triggers["hcp_internal_communication_private_hosted_zone_arn"]
}

output "ingress_private_hosted_zone_id" {
  description = "Ingress Private Hosted Zone ID"
  value       = time_sleep.shared_resources_propagation.triggers["ingress_private_hosted_zone_id"]
}

output "hcp_internal_communication_private_hosted_zone_id" {
  description = "HCP Internal Communication Private Hosted Zone ID"
  value       = time_sleep.shared_resources_propagation.triggers["hcp_internal_communication_private_hosted_zone_id"]
}

output "shared_subnets" {
  description = "The Amazon Resource Names (ARN) of the resource share"
  value       = module.subnets-share.shared_subnets
}
