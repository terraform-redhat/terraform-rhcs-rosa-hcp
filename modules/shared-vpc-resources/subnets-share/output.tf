output "shared_subnets" {
  description = "The Amazon Resource Names (ARN) of the resource share"
  value       = [for resource_arn in aws_ram_resource_association.shared_vpc_resource_association[*].resource_arn : trimprefix(resource_arn, local.resource_arn_prefix)]
}

output "resource_share_arn" {
  description = "Resource Share ARN"
  value       = aws_ram_principal_association.shared_vpc_resource_share.resource_share_arn
}
