# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

output "role_arn" {
  value       = aws_iam_role.ocm_role.arn
  description = "The ARN of the created OCM IAM role."
}

output "role_name" {
  value       = aws_iam_role.ocm_role.name
  description = "The name of the created OCM IAM role."
}

output "role_link_id" {
  value       = try(rhcs_rosa_ocm_role_link.this[0].id, null)
  description = "The identifier of the OCM-side role link created for the IAM role, or null when create_link is false."
}
