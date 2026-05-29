# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

output "role_arn" {
  value       = module.ocm_role.role_arn
  description = "The ARN of the created OCM IAM role."
}

output "role_name" {
  value       = module.ocm_role.role_name
  description = "The name of the created OCM IAM role."
}

output "role_link_id" {
  value       = module.ocm_role.role_link_id
  description = "The identifier of the OCM-side role link."
}
