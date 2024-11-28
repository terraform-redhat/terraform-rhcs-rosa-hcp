output "route53_role" {
  description = "Route53 Role ARN"
  value       = time_sleep.shared_resources_propagation.triggers["route53_role_arn"]
}

output "vpce_role" {
  description = "VPCE Role ARN"
  value       = time_sleep.shared_resources_propagation.triggers["vpce_role_arn"]
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
  value       = [for resource_arn in aws_ram_resource_association.shared_vpc_resource_association[*].resource_arn : trimprefix(resource_arn, local.resource_arn_prefix)]
}