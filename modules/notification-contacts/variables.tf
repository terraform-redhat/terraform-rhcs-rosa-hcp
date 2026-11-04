# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

// Required
variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

// Required
variable "contacts" {
  description = "Set of OCM account usernames to receive cluster notifications. This resource is authoritative: the full set of notification contacts is managed by Terraform."
  type        = set(string)

  validation {
    condition     = length(var.contacts) > 0
    error_message = "At least one notification contact must be specified."
  }

  validation {
    condition = alltrue([
      for c in var.contacts : trimspace(c) != ""
    ])
    error_message = "Each notification contact must be a non-empty string (not blank or whitespace)."
  }
}
