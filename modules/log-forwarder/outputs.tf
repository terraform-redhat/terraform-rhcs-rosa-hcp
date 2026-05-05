# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

output "id" {
  description = "Unique identifier of the log forwarder."
  value       = rhcs_log_forwarder.this.id
}
