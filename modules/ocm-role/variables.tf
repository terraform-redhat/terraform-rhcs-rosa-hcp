# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

variable "ocm_role_prefix" {
  type        = string
  description = "User-defined prefix for the OCM IAM role name. The final role name is `<prefix>-OCM-Role-<organization_external_id>`."

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.ocm_role_prefix))
    error_message = "ocm_role_prefix must match [\\w+=,.@-]+ (alphanumeric, plus, equals, comma, period, at, hyphen)."
  }

  validation {
    condition     = length(var.ocm_role_prefix) <= 32
    error_message = "ocm_role_prefix must be 32 characters or fewer."
  }
}

variable "profile" {
  type        = string
  description = "Profile of the OCM role to create. Allowed values are `standard`, `admin`, and `no-console`."
  default     = "standard"

  validation {
    condition     = contains(["standard", "admin", "no-console"], var.profile)
    error_message = "profile must be one of: standard, admin, no-console."
  }
}

variable "path" {
  type        = string
  description = "(Optional) The IAM path for the OCM role and its policies. Must begin and end with '/'."
  default     = "/"

  validation {
    condition     = var.path == "/" || can(regex("^/.+/$", var.path))
    error_message = "path must be '/' or a value that begins and ends with '/'."
  }
}

variable "permissions_boundary" {
  type        = string
  description = "(Optional) The ARN of the policy used to set the permissions boundary for the OCM IAM role."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Additional AWS resource tags to merge into the OCM role and its policies."
  default     = null
}

variable "create_link" {
  type        = bool
  description = "(Optional) Whether to link the created role to the OCM organization via rhcs_rosa_ocm_role_link. Set to false when importing an already-linked role."
  default     = true
}
