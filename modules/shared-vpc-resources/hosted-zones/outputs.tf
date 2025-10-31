output "ingress_private_hosted_zone_arn" {
  description = "Ingress Private Hosted Zone ARN"
  value       = aws_route53_zone.ingress_private_hosted_zone.arn
}

output "ingress_private_hosted_zone_id" {
  description = "Ingress Private Hosted Zone ID"
  value       = var.create_association_authorization ? aws_route53_vpc_association_authorization.ingress_hz_association_auth[0].zone_id : aws_route53_zone.ingress_private_hosted_zone.id
}

output "hcp_internal_communication_private_hosted_zone_arn" {
  description = "HCP Internal Communication Private Hosted Zone ARN"
  value       = aws_route53_zone.hcp_internal_communication_hosted_zone.arn
}

output "hcp_internal_communication_private_hosted_zone_id" {
  description = "HCP Internal Communication Private Hosted Zone ID"
  value       = var.create_association_authorization ? aws_route53_vpc_association_authorization.hcp_internal_comm_hz_association_auth[0].zone_id : aws_route53_zone.hcp_internal_communication_hosted_zone.id
}
