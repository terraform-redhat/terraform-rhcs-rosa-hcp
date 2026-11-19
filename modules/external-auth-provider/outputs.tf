# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

output "id" {
  description = "Identifier of the external authentication provider, which is its OCM name, or null when create_external_auth_provider is false."
  value       = try(rhcs_external_auth_provider.this[0].id, null)
}
